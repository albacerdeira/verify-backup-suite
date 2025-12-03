#!/bin/bash
# ============================================
# FULL BACKUP LOCAL (SEMANAL)
# Dump completo do banco com compressão
# ============================================

set -e

###########################################################
# CONFIGURAÇÃO DE ACESSO AO BANCO DE DADOS DE PRODUÇÃO
# Use estas credenciais para backup do banco REAL (produção)
# Se quiser backup de teste, troque para as credenciais de teste abaixo
###########################################################
# --- PRODUÇÃO ---
DB_HOST="srv1893.hstgr.io"      # Host do banco de produção (ou "193.203.175.215")
DB_USER="u640879529_kyc"        # Usuário principal do banco de produção
DB_PASS="Bwc52915fgw329@!!@"     # Senha do banco de produção
DB_NAME="u640879529_kyc"         # Nome do banco de produção

# --- TESTE/Backup secundário (exemplo, comente se não usar) ---
# DB_HOST="srv1893.hstgr.io"
# DB_USER="u640879529_kyc_back_fc"
# DB_PASS="123##QweR"
# DB_NAME="u640879529_kyc_back_fc"
BACKUP_DIR="$HOME/backup_suite/backups"
LOG_DIR="$HOME/backup_suite/logs"


# Criar logs
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILE="$BACKUP_DIR/${DB_NAME}_FULL_${TIMESTAMP}.sql"
LOG_FILE="$LOG_DIR/backup_full_${TIMESTAMP}.log"

echo "[$(date)] Iniciando backup full..." >> $LOG_FILE

# Fazer dump completo (sem locks, para não bloquear produção)

# --- ACESSO AO BANCO DE DADOS (PRODUÇÃO ou TESTE) ---
mysqldump -h $DB_HOST -u $DB_USER -p"$DB_PASS" \
  --single-transaction \
  --quick \
  --lock-tables=false \
  $DB_NAME > $DUMP_FILE 2>> $LOG_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] Dump criado com sucesso" >> $LOG_FILE
    
    # Comprimir
    gzip $DUMP_FILE
    DUMP_FILE="${DUMP_FILE}.gz"
    
    # Calcular hash para integridade
    sha256sum $DUMP_FILE > "${DUMP_FILE}.sha256"
    
    BACKUP_SIZE=$(du -h $DUMP_FILE | cut -f1)
    echo "[$(date)] Arquivo comprimido: $DUMP_FILE ($BACKUP_SIZE)" >> $LOG_FILE
    
    # Manter apenas últimos 4 full backups (4 semanas)
    find $BACKUP_DIR -name "${DB_NAME}_FULL_*.sql.gz" -mtime +28 -delete
    
    echo "[$(date)] ✓ Backup full concluído com sucesso" >> $LOG_FILE
    echo "✓ SUCESSO: $BACKUP_FILE ($BACKUP_SIZE)"
else
    echo "[$(date)] ✗ ERRO ao fazer dump" >> $LOG_FILE
    echo "✗ ERRO: Falha ao fazer backup. Verifique $LOG_FILE"
    exit 1
fi
