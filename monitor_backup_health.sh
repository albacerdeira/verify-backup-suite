#!/bin/bash
# ============================================
# MONITOR DE SAÚDE DOS BACKUPS
# Verifica integridade e envia alertas
# ============================================

# Carregar variáveis do .env
if [ -f "/home/u640879529/domains/verifyonline.com.br/public_html/.env" ]; then
    export $(grep -v '^#' /home/u640879529/domains/verifyonline.com.br/public_html/.env | xargs)
else
    echo "[ERRO] Arquivo .env não encontrado!"
    exit 1
fi

# Configurar fuso horário
export TZ=${TIMEZONE:-America/Sao_Paulo}

echo "[$(date)] Iniciando monitoramento de backups..."

# Configuração
BACKUP_DIR="${BACKUP_DIR:-/home/u640879529/backup_suite/backups}"
BACKUP_DIR_INC="${INCREMENTAL_DIR:-/home/u640879529/backup_suite/backups/incremental}"
LOG_DIR="/home/u640879529/backup_suite/logs"
STATUS_FILE="/home/u640879529/backup_suite/status.json"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/monitor_${TIMESTAMP}.log"

# Limites de alerta
MAX_HOURS_WITHOUT_BACKUP=24
MIN_DISK_SPACE_MB=1000

# Inicializar contadores
ALERTS=0
WARNINGS=0
STATUS="OK"

echo "[$(date)] Monitoramento iniciado" | tee -a $LOG_FILE

# ============================================
# VERIFICAÇÃO 1: Último Backup FULL
# ============================================
echo "[$(date)] Verificando último backup FULL..." | tee -a $LOG_FILE

LATEST_FULL=$(ls -t $BACKUP_DIR/backup_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_FULL" ]; then
    echo "[$(date)] ✗ ALERTA CRÍTICO: Nenhum backup FULL encontrado!" | tee -a $LOG_FILE
    ALERTS=$((ALERTS + 1))
    STATUS="CRITICAL"
    LAST_FULL_AGE="0"
    LAST_FULL_SIZE="0"
else
    LAST_FULL_AGE=$(( ( $(date +%s) - $(stat -c %Y "$LATEST_FULL") ) / 3600 ))
    LAST_FULL_SIZE=$(du -h "$LATEST_FULL" | cut -f1)
    
    echo "[$(date)] Último backup FULL: $(basename $LATEST_FULL)" | tee -a $LOG_FILE
    echo "[$(date)] Idade: ${LAST_FULL_AGE}h, Tamanho: $LAST_FULL_SIZE" | tee -a $LOG_FILE
    
    if [ $LAST_FULL_AGE -gt 168 ]; then
        echo "[$(date)] ⚠ AVISO: Backup FULL com mais de 7 dias!" | tee -a $LOG_FILE
        WARNINGS=$((WARNINGS + 1))
        STATUS="WARNING"
    fi
    
    # Verificar integridade SHA256
    if [ -f "${LATEST_FULL}.sha256" ]; then
        echo "[$(date)] Verificando integridade SHA256..." | tee -a $LOG_FILE
        cd $(dirname "$LATEST_FULL")
        if sha256sum -c "$(basename ${LATEST_FULL}.sha256)" >> $LOG_FILE 2>&1; then
            echo "[$(date)] ✓ Integridade verificada" | tee -a $LOG_FILE
        else
            echo "[$(date)] ✗ ALERTA: Falha na verificação!" | tee -a $LOG_FILE
            ALERTS=$((ALERTS + 1))
            STATUS="CRITICAL"
        fi
        cd - > /dev/null
    fi
fi

# ============================================
# VERIFICAÇÃO 2: Último Backup Incremental
# ============================================
echo "[$(date)] Verificando backup incremental..." | tee -a $LOG_FILE

LATEST_INC=$(ls -t $BACKUP_DIR_INC/incremental_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_INC" ]; then
    LAST_INC_AGE="0"
    LAST_INC_SIZE="0"
else
    LAST_INC_AGE=$(( ( $(date +%s) - $(stat -c %Y "$LATEST_INC") ) / 3600 ))
    LAST_INC_SIZE=$(du -h "$LATEST_INC" | cut -f1)
    echo "[$(date)] Último incremental: $(basename $LATEST_INC) (${LAST_INC_AGE}h)" | tee -a $LOG_FILE
    
    if [ $LAST_INC_AGE -gt $MAX_HOURS_WITHOUT_BACKUP ]; then
        echo "[$(date)] ✗ ALERTA: Incremental com +${MAX_HOURS_WITHOUT_BACKUP}h!" | tee -a $LOG_FILE
        ALERTS=$((ALERTS + 1))
        if [ "$STATUS" != "CRITICAL" ]; then STATUS="WARNING"; fi
    fi
fi

# ============================================
# VERIFICAÇÃO 3: Espaço em Disco
# ============================================
echo "[$(date)] Verificando espaço..." | tee -a $LOG_FILE

DISK_AVAILABLE=$(df -m /home/u640879529 | tail -1 | awk '{print $4}')
DISK_USED_PERCENT=$(df -h /home/u640879529 | tail -1 | awk '{print $5}' | sed 's/%//')

echo "[$(date)] Disponível: ${DISK_AVAILABLE}MB, Uso: ${DISK_USED_PERCENT}%" | tee -a $LOG_FILE

if [ $DISK_AVAILABLE -lt $MIN_DISK_SPACE_MB ]; then
    echo "[$(date)] ✗ ALERTA: Pouco espaço!" | tee -a $LOG_FILE
    ALERTS=$((ALERTS + 1))
    STATUS="CRITICAL"
elif [ $DISK_USED_PERCENT -gt 85 ]; then
    echo "[$(date)] ⚠ AVISO: Uso >85%" | tee -a $LOG_FILE
    WARNINGS=$((WARNINGS + 1))
    if [ "$STATUS" == "OK" ]; then STATUS="WARNING"; fi
fi

# ============================================
# VERIFICAÇÃO 4: Contagem de Backups
# ============================================
FULL_COUNT=$(ls $BACKUP_DIR/backup_*.sql.gz 2>/dev/null | wc -l)
INC_COUNT=$(ls $BACKUP_DIR_INC/incremental_*.sql.gz 2>/dev/null | wc -l)

echo "[$(date)] Backups FULL: $FULL_COUNT, Incrementais: $INC_COUNT" | tee -a $LOG_FILE

# ============================================
# GERAR STATUS JSON
# ============================================
cat > $STATUS_FILE << EOF
{
  "timestamp": "$(date '+%Y-%m-%d %H:%M:%S')",
  "status": "$STATUS",
  "alerts": $ALERTS,
  "warnings": $WARNINGS,
  "backups": {
    "full": {"count": $FULL_COUNT, "age_hours": $LAST_FULL_AGE, "size": "$LAST_FULL_SIZE"},
    "incremental": {"count": $INC_COUNT, "age_hours": $LAST_INC_AGE, "size": "$LAST_INC_SIZE"}
  },
  "disk": {"available_mb": $DISK_AVAILABLE, "used_percent": $DISK_USED_PERCENT}
}
EOF

# ============================================
# ENVIAR NOTIFICAÇÃO SE HOUVER PROBLEMAS
# ============================================
if [ $ALERTS -gt 0 ]; then
    DETAILS="Status: $STATUS\nAlertas: $ALERTS\nAvisos: $WARNINGS\n\nÚltimo FULL: ${LAST_FULL_AGE}h ($LAST_FULL_SIZE)\nÚltimo Inc: ${LAST_INC_AGE}h\nEspaço: ${DISK_AVAILABLE}MB (${DISK_USED_PERCENT}%)"
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "🚨 Monitoramento: ALERTAS Detectados" "$DETAILS" >> $LOG_FILE 2>&1
elif [ $WARNINGS -gt 0 ]; then
    DETAILS="Avisos: $WARNINGS\n\nÚltimo FULL: ${LAST_FULL_AGE}h\nEspaço: ${DISK_AVAILABLE}MB"
    php /home/u640879529/backup_suite/send_backup_notification.php "sucesso" "⚠ Monitoramento: Avisos" "$DETAILS" >> $LOG_FILE 2>&1
fi

echo "[$(date)] ✓ Monitor finalizado - Status: $STATUS" | tee -a $LOG_FILE
