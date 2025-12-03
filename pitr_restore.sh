#!/bin/bash
# ============================================
# PITR: Point-in-Time Restore
# Restaura banco para um horário específico
# ============================================

set -e

# CONFIGURAR ESTAS VARIÁVEIS
RESTORE_TIME="2025-12-01 09:00:00"  # Horário que quer restaurar
DB_USER="root"
DB_PASS="sua_senha_root_aqui"
BACKUP_DIR="/backups/local/full"
BINLOG_DIR="/backups/local/incremental"
RESTORE_DB="verify_production_restore"
LOG_DIR="/backups/local/logs"

mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pitr_restore_$(date +%s).log"

echo "[$(date)] Iniciando PITR para: $RESTORE_TIME" > $LOG

# 1) Encontrar full backup anterior ao tempo
echo "[$(date)] Procurando backup anterior a $RESTORE_TIME..." >> $LOG
LATEST_FULL=$(ls -t $BACKUP_DIR/verify_production_FULL_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_FULL" ]; then
    echo "[$(date)] ✗ Nenhum backup full encontrado" >> $LOG
    cat $LOG
    exit 1
fi

echo "[$(date)] Usando backup: $LATEST_FULL" >> $LOG

# 2) Criar DB restauração (não sobrescrever produção)
echo "[$(date)] Criando database $RESTORE_DB..." >> $LOG
mysql -u $DB_USER -p"$DB_PASS" << SQL >> $LOG 2>&1
CREATE DATABASE IF NOT EXISTS $RESTORE_DB;
SQL

# 3) Restaurar dump full
echo "[$(date)] Restaurando dump full..." >> $LOG
gunzip -c "$LATEST_FULL" | mysql -u $DB_USER -p"$DB_PASS" $RESTORE_DB >> $LOG 2>&1

# 4) Aplicar binlogs (replay até o ponto no tempo)
echo "[$(date)] Aplicando binlogs incrementais..." >> $LOG
if [ -d "$BINLOG_DIR" ]; then
    for binlog in $(ls -t $BINLOG_DIR/mysql-bin.*.gz 2>/dev/null); do
        echo "[$(date)] Processando: $(basename $binlog)" >> $LOG
        gunzip -c "$binlog" | mysqlbinlog \
            --start-datetime="$(date -d "$RESTORE_TIME" '+%Y-%m-%d %H:%M:%S')" \
            --stop-datetime="$(date -d "$RESTORE_TIME + 10 seconds" '+%Y-%m-%d %H:%M:%S')" \
            | mysql -u $DB_USER -p"$DB_PASS" $RESTORE_DB >> $LOG 2>&1 || true
    done
fi

# 5) Validar dados
echo "[$(date)] Validando dados restaurados..." >> $LOG
mysql -u $DB_USER -p"$DB_PASS" -e "SELECT COUNT(*) as users FROM $RESTORE_DB.usuarios; SELECT COUNT(*) as kyc FROM $RESTORE_DB.kyc_socios;" >> $LOG

# 6) Informações finais
echo "[$(date)] ✓ PITR CONCLUÍDO" >> $LOG
echo "[$(date)] Database de teste: $RESTORE_DB" >> $LOG

cat $LOG
echo ""
echo "⚠️  PRÓXIMOS PASSOS (MANUAL):"
echo "1) Verificar dados em: $RESTORE_DB"
echo "2) Comparar com produção"
echo "3) Se OK, fazer swap:"
echo "   RENAME TABLE verify_production TO verify_production_backup, $RESTORE_DB TO verify_production;"
echo "4) Se NOK, limpar: DROP DATABASE $RESTORE_DB;"
