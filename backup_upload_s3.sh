#!/bin/bash
# ============================================
# UPLOAD BACKUP PARA AWS S3
# Diário: envia full backup mais recente
# ============================================

set -e

# CONFIGURAR ESTAS VARIÁVEIS
BACKUP_DIR="/backups/local/full"
S3_BUCKET="s3://verify-backups-production"
AWS_PROFILE="default"
LOG_DIR="/backups/local/logs"
TIMESTAMP=$(date +"%Y%m%d")
LOG_FILE="$LOG_DIR/s3_upload_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

echo "[$(date)] Iniciando upload para S3..." >> $LOG_FILE

# Encontrar arquivo full backup mais recente
LATEST_BACKUP=$(ls -t $BACKUP_DIR/verify_production_FULL_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "[$(date)] ✗ Nenhum backup full encontrado" >> $LOG_FILE
    exit 1
fi

FILENAME=$(basename $LATEST_BACKUP)

# Verificar se já foi enviado (comparar com S3)
aws s3 ls "$S3_BUCKET/full/$FILENAME" --profile $AWS_PROFILE 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[$(date)] ℹ Arquivo já existe em S3: $FILENAME" >> $LOG_FILE
    exit 0
fi

# Upload para S3
echo "[$(date)] Enviando: $FILENAME" >> $LOG_FILE
aws s3 cp "$LATEST_BACKUP" "$S3_BUCKET/full/${FILENAME}" \
  --profile $AWS_PROFILE \
  --sse AES256 \
  --storage-class STANDARD \
  --metadata "backup-date=$(date -I),server=production" \
  2>> $LOG_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Upload concluído: s3://verify-backups-production/full/$FILENAME" >> $LOG_FILE
    
    # Também fazer upload do checksum
    aws s3 cp "${LATEST_BACKUP}.sha256" "$S3_BUCKET/full/${FILENAME}.sha256" \
      --profile $AWS_PROFILE \
      --sse AES256 \
      2>> $LOG_FILE
else
    echo "[$(date)] ✗ ERRO ao fazer upload para S3" >> $LOG_FILE
    exit 1
fi

# Listar últimos 10 backups no S3
echo "[$(date)] Últimos backups no S3:" >> $LOG_FILE
aws s3 ls "$S3_BUCKET/full/" --profile $AWS_PROFILE | tail -10 >> $LOG_FILE
