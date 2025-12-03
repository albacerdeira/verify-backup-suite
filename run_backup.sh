#!/bin/bash
# =================================================================
# WRAPPER PARA CRON DA HOSTINGER
# Este script é específico para ser chamado pelo cron job
# Redireciona toda saída para cron.log conforme requisitos Hostinger
# =================================================================

# Garantir permissão de execução antes de rodar
chmod +x /home/u640879529/backup_suite/backup_full_local.sh

# Chamar com bash explícito para garantir execução
/bin/bash /home/u640879529/backup_suite/backup_full_local.sh > /home/u640879529/backup_suite/cron.log 2>&1

