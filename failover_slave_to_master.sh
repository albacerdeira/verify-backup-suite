#!/bin/bash
# ============================================
# FAILOVER: Promover Slave para Master
# Use em caso de emergência
# ============================================

set -e

# CONFIGURAR ESTAS VARIÁVEIS
SLAVE_IP="seu_ip_slave_aqui"
MASTER_IP="seu_ip_master_aqui"
DB_USER="root"
DB_PASS="sua_senha_root_aqui"
LOG_DIR="/backups/local/logs"

mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/failover_$(date +%s).log"

echo "[$(date)] INICIANDO FAILOVER: Promover Slave para Master" > $LOG
echo "[$(date)] Slave: $SLAVE_IP" >> $LOG
echo "[$(date)] Master (original): $MASTER_IP" >> $LOG

# 1) Parar replicação no slave
echo "[$(date)] Parando replicação no slave..." >> $LOG
mysql -h $SLAVE_IP -u $DB_USER -p"$DB_PASS" << SQL >> $LOG 2>&1
STOP SLAVE;
SQL

if [ $? -ne 0 ]; then
    echo "[$(date)] ✗ ERRO ao parar slave" >> $LOG
    cat $LOG
    exit 1
fi

# 2) Promover slave para master (remover read-only)
echo "[$(date)] Promovendo slave para master..." >> $LOG
mysql -h $SLAVE_IP -u $DB_USER -p"$DB_PASS" << SQL >> $LOG 2>&1
SET GLOBAL read_only = OFF;
SET GLOBAL super_read_only = OFF;
SQL

# 3) Resetar master info (remove replicação)
echo "[$(date)] Resetando informações de slave..." >> $LOG
mysql -h $SLAVE_IP -u $DB_USER -p"$DB_PASS" -e "RESET SLAVE ALL;" >> $LOG 2>&1

# 4) Verificar novo master
echo "[$(date)] Verificando novo master..." >> $LOG
mysql -h $SLAVE_IP -u $DB_USER -p"$DB_PASS" -e "SHOW MASTER STATUS\G" >> $LOG

echo "[$(date)] ✓ FAILOVER CONCLUÍDO" >> $LOG
echo "[$(date)] Novo Master: $SLAVE_IP" >> $LOG

cat $LOG
echo ""
echo "⚠️  PRÓXIMOS PASSOS (MANUAL):"
echo "1) Atualizar config da aplicação com novo Master: $SLAVE_IP"
echo "2) Reiniciar aplicação"
echo "3) Restaurar master original após diagnosticar falha"
