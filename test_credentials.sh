#!/bin/bash
# Script de teste local para verificar credenciais

# Carregar .env da mesma pasta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' $ENV_FILE | xargs)
    echo "✓ .env carregado de $ENV_FILE"
else
    echo "✗ .env não encontrado em $ENV_FILE"
    exit 1
fi

echo ""
echo "=== CREDENCIAIS CARREGADAS ==="
echo "DB_HOST: $DB_HOST"
echo "DB_USER: $DB_USER"
echo "DB_NAME: $DB_NAME"
echo "DB_PASS: ${DB_PASS:0:5}***"
echo ""
echo "DB_SECONDARY_HOST: $DB_SECONDARY_HOST"
echo "DB_SECONDARY_USER: $DB_SECONDARY_USER"
echo ""
echo "AWS_BACKUP_BUCKET: $AWS_BACKUP_BUCKET"
echo "AWS_BACKUP_REGION: $AWS_BACKUP_REGION"
echo "AWS_BACKUP_ACCESS_KEY: ${AWS_BACKUP_ACCESS_KEY:0:10}***"
echo ""
echo "SMTP_HOST: $SMTP_HOST"
echo "SMTP_USER: $SMTP_USER"
echo "EMAIL_TO: $EMAIL_TO"
echo ""
echo "BACKUP_DIR: $BACKUP_DIR"
echo "TIMEZONE: $TIMEZONE"
