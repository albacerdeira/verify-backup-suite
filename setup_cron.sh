#!/bin/bash
# ============================================
# AGENDAMENTO DE BACKUP (Cron Jobs)
# Execute uma vez para agendar todos os scripts
# ============================================

echo "Configurando agendamento de backup via cron..."

BACKUP_SUITE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Função para adicionar cron job (sem duplicar)
add_cron() {
    local cmd="$1"
    local schedule="$2"
    
    (crontab -l 2>/dev/null | grep -F "$cmd") > /dev/null 2>&1 || \
        (crontab -l 2>/dev/null; echo "$schedule $cmd") | crontab -
}

# Full backup: Domingo 2 AM
add_cron "bash $BACKUP_SUITE_DIR/backup_full_local.sh" "0 2 * * 0"

# Incremental backup: Diário 2:30 AM
add_cron "bash $BACKUP_SUITE_DIR/backup_incremental_local.sh" "30 2 * * *"

# Upload S3: Diário 3 AM
add_cron "bash $BACKUP_SUITE_DIR/backup_upload_s3.sh" "0 3 * * *"

# Limpeza de backups antigos: Segunda-feira 4 AM
add_cron "bash $BACKUP_SUITE_DIR/cleanup_old_backups.sh" "0 4 * * 1"

# Monitoramento: A cada 30 minutos
add_cron "bash $BACKUP_SUITE_DIR/monitor_backup_health.sh" "*/30 * * * *"

# Air-gapped backup: 1º do mês 4 AM (MANUAL - comentado)
# add_cron "bash $BACKUP_SUITE_DIR/backup_air_gapped.sh" "0 4 1 * *"

echo ""
echo "✓ Cron jobs agendados!"
echo ""
echo "Agenda:"
echo "  0 2 * * 0   → Full backup (domingo 2 AM)"
echo "  30 2 * * *  → Incremental backup (diário 2:30 AM)"
echo "  0 3 * * *   → Upload S3 (diário 3 AM)"
echo "  0 4 * * 1   → Limpeza (segunda-feira 4 AM)"
echo "  */30 * * * * → Monitoramento (a cada 30 min)"
echo ""
echo "Ver crontab: crontab -l"
echo "Editar crontab: crontab -e"
