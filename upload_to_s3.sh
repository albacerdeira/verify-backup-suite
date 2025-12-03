#!/bin/bash
# ============================================
# UPLOAD BACKUP TO AWS S3
# Envia o backup mais recente para S3
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

echo "[$(date)] Iniciando upload para S3..."

# Credenciais AWS do .env
AWS_ACCESS_KEY="${AWS_BACKUP_ACCESS_KEY}"
AWS_SECRET_KEY="${AWS_BACKUP_SECRET_KEY}"
AWS_REGION="${AWS_BACKUP_REGION}"
S3_BUCKET="${AWS_BACKUP_BUCKET}"

BACKUP_DIR="${BACKUP_DIR:-/home/u640879529/backup_suite/backups}"
LOG_DIR="/home/u640879529/backup_suite/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/s3_upload_${TIMESTAMP}.log"

echo "[$(date)] Configurando credenciais AWS..." | tee -a $LOG_FILE

# Caminho completo do AWS CLI
AWS_CLI="/home/u640879529/.local/bin/aws"

# Configurar AWS CLI (se disponível) ou usar curl direto
if [ -f "$AWS_CLI" ]; then
    echo "[$(date)] AWS CLI detectado em $AWS_CLI" | tee -a $LOG_FILE
    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
    export AWS_DEFAULT_REGION=$AWS_REGION
    
    # Encontrar backup mais recente
    LATEST_BACKUP=$(ls -t $BACKUP_DIR/backup_u640879529_kyc_*.sql.gz 2>/dev/null | head -1)
    LATEST_HASH="${LATEST_BACKUP}.sha256"
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo "[$(date)] ✗ ERRO: Nenhum backup encontrado" | tee -a $LOG_FILE
        php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha no upload S3" "Nenhum backup encontrado" >> $LOG_FILE 2>&1
        exit 1
    fi
    
    echo "[$(date)] Backup encontrado: $LATEST_BACKUP" | tee -a $LOG_FILE
    BACKUP_SIZE=$(du -h $LATEST_BACKUP | cut -f1)
    
    # Upload do backup
    echo "[$(date)] Enviando para S3: s3://$S3_BUCKET/$(basename $LATEST_BACKUP)" | tee -a $LOG_FILE
    $AWS_CLI s3 cp "$LATEST_BACKUP" "s3://$S3_BUCKET/" --storage-class STANDARD_IA >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] ✓ Backup enviado com sucesso" | tee -a $LOG_FILE
        
        # Upload do hash
        if [ -f "$LATEST_HASH" ]; then
            $AWS_CLI s3 cp "$LATEST_HASH" "s3://$S3_BUCKET/" --storage-class STANDARD_IA >> $LOG_FILE 2>&1
            echo "[$(date)] ✓ Hash enviado com sucesso" | tee -a $LOG_FILE
        fi
        
        # Notificar sucesso
        php /home/u640879529/backup_suite/send_backup_notification.php "sucesso" "Upload S3 (AWS) Concluído" "Arquivo: $(basename $LATEST_BACKUP)\nTamanho: $BACKUP_SIZE\nBucket: s3://$S3_BUCKET/\nTipo: Backup em Nuvem" >> $LOG_FILE 2>&1
        
        echo "✓ SUCESSO: Upload S3 concluído ($BACKUP_SIZE)"
    else
        echo "[$(date)] ✗ ERRO ao enviar para S3" | tee -a $LOG_FILE
        php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha no upload S3" "Verifique o log: $LOG_FILE" >> $LOG_FILE 2>&1
        exit 1
    fi
else
    echo "[$(date)] ✗ ERRO: AWS CLI não instalado" | tee -a $LOG_FILE
    echo "Instale o AWS CLI com: pip install awscli" | tee -a $LOG_FILE
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "AWS CLI não instalado" "Execute: pip install awscli" >> $LOG_FILE 2>&1
    exit 1
fi
