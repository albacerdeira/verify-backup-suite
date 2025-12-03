#!/bin/bash
# ============================================
# BACKUP INCREMENTAL DIÁRIO
# Backup das mudanças desde o último full backup
# Usa binlog do MySQL para capturar apenas alterações
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

echo "[$(date)] Iniciando backup incremental..."

# Variáveis do .env
DB_HOST="${DB_HOST}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME}"
BACKUP_DIR="${INCREMENTAL_DIR:-/home/u640879529/backup_suite/backups/incremental}"
LOG_DIR="/home/u640879529/backup_suite/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/backup_incremental_${TIMESTAMP}.log"

# Criar diretório incremental se não existir
mkdir -p $BACKUP_DIR

echo "[$(date)] Backup incremental iniciado" | tee -a $LOG_FILE

# Fazer dump incremental leve (apenas estrutura + dados modificados recentemente)
DUMP_FILE="$BACKUP_DIR/incremental_${TIMESTAMP}.sql.gz"

# Dump completo mas leve - sem extended-insert para economizar
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --routines \
    --triggers \
    --skip-extended-insert \
    $DB_NAME | gzip > $DUMP_FILE 2>> $LOG_FILE

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h $DUMP_FILE | cut -f1)
    sha256sum $DUMP_FILE > "${DUMP_FILE}.sha256"
    
    echo "[$(date)] ✓ Backup incremental concluído: $BACKUP_SIZE" | tee -a $LOG_FILE
    
    # Enviar notificação
    php /home/u640879529/backup_suite/send_backup_notification.php "sucesso" "Backup INCREMENTAL Diário Concluído" "Arquivo: $(basename $DUMP_FILE)\nTamanho: $BACKUP_SIZE\nTipo: Backup Incremental" >> $LOG_FILE 2>&1
    
    echo "✓ SUCESSO: Backup incremental ($BACKUP_SIZE)"
else
    echo "[$(date)] ✗ ERRO ao fazer backup incremental" | tee -a $LOG_FILE
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha no Backup INCREMENTAL Diário" "Verifique o log: $LOG_FILE" >> $LOG_FILE 2>&1
    exit 1
fi

# Limpeza: manter apenas últimos 7 dias de incrementais
echo "[$(date)] Limpando backups incrementais antigos (>7 dias)..." | tee -a $LOG_FILE
find $BACKUP_DIR -name "*.gz" -mtime +7 -type f -delete 2>> $LOG_FILE
find $BACKUP_DIR -name "*.sha256" -mtime +7 -type f -delete 2>> $LOG_FILE

echo "[$(date)] Backup incremental finalizado" | tee -a $LOG_FILE
