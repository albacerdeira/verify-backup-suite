#!/bin/bash
# ============================================
# AIR-GAPPED BACKUP (Mensal)
# Copia backup para disco externo (offline)
# Protegido contra ransomware
# ============================================

set -e

# CONFIGURAR ESTAS VARIÁVEIS
BACKUP_DIR="/backups/local/full"
EXTERNAL_DISK="/mnt/backup-externo"
S3_BUCKET="s3://verify-backups-production"
AWS_PROFILE="default"
LOG_DIR="/backups/local/logs"

mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/air_gapped_$(date +%Y%m%d_%H%M%S).log"

echo "[$(date)] Iniciando Air-gapped Backup..." > $LOG

# 1) Verificar se disco externo está montado
if ! mountpoint -q "$EXTERNAL_DISK"; then
    echo "[$(date)] ✗ ERRO: Disco externo NÃO está montado em $EXTERNAL_DISK" >> $LOG
    echo "[$(date)] Conecte o disco externo e monte com:" >> $LOG
    echo "  sudo mount /dev/sdbX $EXTERNAL_DISK" >> $LOG
    cat $LOG
    exit 1
fi

# 2) Download do backup mais recente do S3
echo "[$(date)] Baixando backup mais recente do S3..." >> $LOG
LATEST=$(aws s3 ls "$S3_BUCKET/full/" --profile $AWS_PROFILE | tail -1 | awk '{print $4}')

if [ -z "$LATEST" ]; then
    echo "[$(date)] ✗ Nenhum backup encontrado em S3" >> $LOG
    cat $LOG
    exit 1
fi

echo "[$(date)] Baixando: $LATEST" >> $LOG
aws s3 cp "$S3_BUCKET/full/$LATEST" "$EXTERNAL_DISK/" --profile $AWS_PROFILE >> $LOG 2>&1

# 3) Verificar integridade (hash)
echo "[$(date)] Verificando integridade..." >> $LOG
aws s3 cp "$S3_BUCKET/full/${LATEST}.sha256" "$EXTERNAL_DISK/" --profile $AWS_PROFILE >> $LOG 2>&1

cd "$EXTERNAL_DISK"
COMPUTED_HASH=$(sha256sum "$LATEST" | cut -d' ' -f1)
FILE_HASH=$(cut -d' ' -f1 "${LATEST}.sha256")

if [ "$COMPUTED_HASH" = "$FILE_HASH" ]; then
    echo "[$(date)] ✓ Integridade verificada: OK" >> $LOG
else
    echo "[$(date)] ✗ ERRO: Hash não corresponde!" >> $LOG
    echo "[$(date)] Computed: $COMPUTED_HASH" >> $LOG
    echo "[$(date)] File: $FILE_HASH" >> $LOG
    exit 1
fi

# 4) Criptografar com GPG (opcional mas recomendado)
echo "[$(date)] Criptografando arquivo..." >> $LOG
if command -v gpg &> /dev/null; then
    # Usar GPG se instalado
    gpg --symmetric --cipher-algo AES256 --batch --yes \
        --passphrase "sua_senha_gpg_aqui" \
        "$EXTERNAL_DISK/$LATEST" >> $LOG 2>&1
    
    # Remover original (apenas criptografado)
    rm "$EXTERNAL_DISK/$LATEST"
    echo "[$(date)] Arquivo criptografado e original removido" >> $LOG
else
    echo "[$(date)] ℹ GPG não encontrado, pulando criptografia" >> $LOG
fi

# 5) Desmontar disco (proteção contra modificação)
echo "[$(date)] Desmontando disco externo..." >> $LOG
umount "$EXTERNAL_DISK"

echo "[$(date)] ✓ Air-gapped Backup concluído com sucesso" >> $LOG
echo "[$(date)] Arquivo protegido em: $EXTERNAL_DISK" >> $LOG

cat $LOG
echo ""
echo "✓ BACKUP OFFLINE CRIADO"
echo "⚠️  Desconecte o disco externo para máxima proteção contra ransomware"
