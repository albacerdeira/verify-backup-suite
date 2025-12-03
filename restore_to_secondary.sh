#!/bin/bash
# ============================================
# RESTORE TO SECONDARY DATABASE
# Restaura o backup mais recente no banco secundário
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

echo "[$(date)] Iniciando restauração no banco secundário..."

# Configuração do banco secundário (variáveis do .env)
DB_HOST="${DB_SECONDARY_HOST}"
DB_USER="${DB_SECONDARY_USER}"
DB_PASS="${DB_SECONDARY_PASS}"
DB_NAME="${DB_SECONDARY_NAME}"

BACKUP_DIR="${BACKUP_DIR:-/home/u640879529/backup_suite/backups}"
LOG_DIR="/home/u640879529/backup_suite/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/restore_secondary_${TIMESTAMP}.log"

echo "[$(date)] Buscando backup mais recente..." | tee -a $LOG_FILE

# Encontrar o backup mais recente
LATEST_BACKUP=$(ls -t $BACKUP_DIR/u640879529_kyc_FULL_*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "[$(date)] ✗ ERRO: Nenhum backup encontrado" | tee -a $LOG_FILE
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha na replicação" "Nenhum backup encontrado para restaurar" >> $LOG_FILE 2>&1
    exit 1
fi

echo "[$(date)] Backup encontrado: $LATEST_BACKUP" | tee -a $LOG_FILE

# Verificar integridade do hash
if [ -f "${LATEST_BACKUP}.sha256" ]; then
    echo "[$(date)] Verificando integridade do backup..." | tee -a $LOG_FILE
    cd $(dirname $LATEST_BACKUP)
    if sha256sum -c $(basename ${LATEST_BACKUP}.sha256) >> $LOG_FILE 2>&1; then
        echo "[$(date)] ✓ Hash verificado com sucesso" | tee -a $LOG_FILE
    else
        echo "[$(date)] ✗ ERRO: Hash inválido, backup pode estar corrompido" | tee -a $LOG_FILE
        php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha na replicação" "Backup corrompido (hash inválido)" >> $LOG_FILE 2>&1
        exit 1
    fi
fi

# Descompactar temporariamente
TEMP_SQL="/tmp/restore_temp_${TIMESTAMP}.sql"
TEMP_SQL_CLEAN="/tmp/restore_clean_${TIMESTAMP}.sql"
echo "[$(date)] Descompactando backup..." | tee -a $LOG_FILE
gunzip -c $LATEST_BACKUP > $TEMP_SQL 2>> $LOG_FILE

if [ $? -ne 0 ]; then
    echo "[$(date)] ✗ ERRO ao descompactar backup" | tee -a $LOG_FILE
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha na replicação" "Erro ao descompactar backup" >> $LOG_FILE 2>&1
    rm -f $TEMP_SQL
    exit 1
fi

BACKUP_SIZE=$(du -h $TEMP_SQL | cut -f1)
echo "[$(date)] Backup descompactado: $BACKUP_SIZE" | tee -a $LOG_FILE

# Remover DEFINER e comandos problemáticos para compatibilidade
echo "[$(date)] Limpando comandos incompatíveis (DEFINER, triggers, etc)..." | tee -a $LOG_FILE
sed -e 's/DEFINER=[^ ]*//g' \
    -e 's/\/\*!50013 DEFINER=[^*]*\*\///g' \
    -e 's/\/\*!50017 DEFINER=[^*]*\*\///g' \
    $TEMP_SQL > $TEMP_SQL_CLEAN 2>> $LOG_FILE

echo "[$(date)] Arquivo limpo criado" | tee -a $LOG_FILE

# Restaurar no banco secundário
echo "[$(date)] Restaurando no banco secundário ($DB_NAME)..." | tee -a $LOG_FILE

mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME < $TEMP_SQL_CLEAN 2>> $LOG_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Restauração concluída com sucesso" | tee -a $LOG_FILE
    
    # Limpar arquivos temporários
    rm -f $TEMP_SQL $TEMP_SQL_CLEAN
    
    # Enviar notificação de sucesso
    php /home/u640879529/backup_suite/send_backup_notification.php "sucesso" "Replicação DB Secundário Concluída" "Banco: $DB_NAME\nBackup: $(basename $LATEST_BACKUP)\nTamanho: $BACKUP_SIZE\nTipo: Replicação Automática" >> $LOG_FILE 2>&1
    
    echo "✓ SUCESSO: Banco secundário atualizado ($BACKUP_SIZE)"
else
    echo "[$(date)] ✗ ERRO ao restaurar no banco secundário" | tee -a $LOG_FILE
    rm -f $TEMP_SQL $TEMP_SQL_CLEAN
    
    # Enviar notificação de erro
    php /home/u640879529/backup_suite/send_backup_notification.php "erro" "Falha na replicação para banco secundário" "Verifique o log: $LOG_FILE" >> $LOG_FILE 2>&1
    
    echo "✗ ERRO: Falha ao restaurar. Verifique $LOG_FILE"
    exit 1
fi
