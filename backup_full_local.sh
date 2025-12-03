#!/bin/bash
# ============================================
# FULL BACKUP LOCAL (SEMANAL)
# Dump completo do banco com compressão
# ============================================

# Carregar variáveis do .env (raiz do projeto, fora do public_html)
ENV_FILE="/home/u640879529/.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' $ENV_FILE | xargs)
else
    echo "[ERRO] Arquivo .env não encontrado em $ENV_FILE"
    exit 1
fi

# Configurar fuso horário
export TZ=${TIMEZONE:-America/Sao_Paulo}

echo "[$(date)] Script iniciado"
echo "[$(date)] Permissões do script: $(stat -c %a $0)"
echo "[$(date)] Usuário executando: $(whoami)"
set -e

# Variáveis do .env
DB_HOST="${DB_HOST}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME}"
BACKUP_DIR="${BACKUP_DIR:-/home/u640879529/backup_suite/backups}"
LOG_DIR="/home/u640879529/backup_suite/logs"
echo "[$(date)] Variáveis: HOST=$DB_HOST USER=$DB_USER BANCO=$DB_NAME"


mkdir -p "$LOG_DIR"
echo "[$(date)] Diretório de logs garantido: $LOG_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILE="$BACKUP_DIR/${DB_NAME}_FULL_${TIMESTAMP}.sql"
LOG_FILE="$LOG_DIR/backup_full_${TIMESTAMP}.log"
echo "[$(date)] Arquivo de dump: $DUMP_FILE"
echo "[$(date)] Arquivo de log: $LOG_FILE"

echo "[$(date)] Iniciando backup full..." | tee -a $LOG_FILE

# Fazer dump completo (sem locks, para não bloquear produção)

# --- ACESSO AO BANCO DE DADOS (PRODUÇÃO ou TESTE) ---
mysqldump -h $DB_HOST -u $DB_USER -p"$DB_PASS" \
  --single-transaction \
  --quick \
  --lock-tables=false \
  $DB_NAME > $DUMP_FILE 2>> $LOG_FILE
echo "[$(date)] mysqldump executado (exit=$?)" | tee -a $LOG_FILE

if [ $? -eq 0 ]; then
  echo "[$(date)] Dump criado com sucesso" | tee -a $LOG_FILE
  # Comprimir
  gzip $DUMP_FILE
  DUMP_FILE="${DUMP_FILE}.gz"
  echo "[$(date)] Dump comprimido" | tee -a $LOG_FILE
  # Calcular hash para integridade
  sha256sum $DUMP_FILE > "${DUMP_FILE}.sha256"
  echo "[$(date)] Hash gerado" | tee -a $LOG_FILE
  BACKUP_SIZE=$(du -h $DUMP_FILE | cut -f1)
  echo "[$(date)] Arquivo comprimido: $DUMP_FILE ($BACKUP_SIZE)" | tee -a $LOG_FILE
  # Manter apenas últimos 4 full backups (4 semanas)
  find $BACKUP_DIR -name "${DB_NAME}_FULL_*.sql.gz" -mtime +28 -delete
  echo "[$(date)] Backups antigos removidos" | tee -a $LOG_FILE
  echo "[$(date)] ✓ Backup full concluído com sucesso" | tee -a $LOG_FILE
  echo "✓ SUCESSO: $DUMP_FILE ($BACKUP_SIZE)"
  
  # Enviar email de notificação via PHP
  php /home/u640879529/backup_suite/send_backup_notification.php "sucesso" "Backup FULL Semanal Concluído" "Arquivo: $DUMP_FILE\nTamanho: $BACKUP_SIZE\nTipo: Backup Completo Semanal" >> $LOG_FILE 2>&1
  
  # Replicar para banco secundário
  echo "[$(date)] Iniciando replicação para banco secundário..." | tee -a $LOG_FILE
  /bin/bash /home/u640879529/backup_suite/restore_to_secondary.sh
  
  # Upload para S3
  echo "[$(date)] Iniciando upload para S3..." | tee -a $LOG_FILE
  /bin/bash /home/u640879529/backup_suite/upload_to_s3.sh
else
  echo "[$(date)] ✗ ERRO ao fazer dump" | tee -a $LOG_FILE
  echo "✗ ERRO: Falha ao fazer backup. Verifique $LOG_FILE"
  
  # Enviar email de notificação de erro via PHP
  php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha no Backup FULL Semanal" "Verifique o log: $LOG_FILE" >> $LOG_FILE 2>&1
  exit 1
fi
