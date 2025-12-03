# Configuração Centralizada - Backup Suite

# ============================================
# BANCO DE DADOS
# ============================================
DB_HOST="localhost"
DB_USER="root"
DB_PASS="sua_senha_root_aqui"
DB_NAME="verify_production"
ALERT_EMAIL="albacrodrigues@gmail.com"

# ============================================
# CAMINHOS DE BACKUP
# ============================================
BACKUP_DIR="/backups/local/full"
INCREMENTAL_DIR="/backups/local/incremental"
BINLOG_DIR="/var/log/mysql"
LOG_DIR="/backups/local/logs"

# ============================================
# AWS S3 (para backups remotos)
# ============================================
S3_BUCKET="s3://verify-backups-production"
AWS_PROFILE="default"
# Certifique-se que AWS CLI está configurado:
# aws configure --profile default

# ============================================
# REPLICAÇÃO MySQL (Failover)
# ============================================
SLAVE_IP="seu_ip_slave_aqui"
MASTER_IP="seu_ip_master_aqui"

# ============================================
# PONTO-NO-TEMPO RESTORE (PITR)
# ============================================
RESTORE_TIME="2025-12-01 09:00:00"  # Horário a restaurar
RESTORE_DB="verify_production_restore"

# ============================================
# AIR-GAPPED BACKUP (Disco externo)
# ============================================
EXTERNAL_DISK="/mnt/backup-externo"
GPG_PASSPHRASE="sua_senha_gpg_aqui"

# ============================================
# POLÍTICA DE RETENÇÃO (em dias)
# ============================================
RETAIN_FULL_BACKUP=28      # 4 semanas
RETAIN_INCREMENTAL=14      # 2 semanas
RETAIN_LOGS=30             # 1 mês
RETAIN_BINLOG=10           # MySQL auto-manage

# ============================================
# ALERTAS
# ============================================
ALERT_ON_REPLICATION_ERROR=true
ALERT_ON_BACKUP_FAILURE=true
ALERT_ON_DISK_FULL=true
DISK_WARNING_PERCENT=80
DISK_CRITICAL_PERCENT=95

# ============================================
# COMO USAR
# ============================================
# 1) Preencha as variáveis acima conforme sua infraestrutura
# 2) Os scripts lerão automaticamente este arquivo (via source)
# 3) Não commitar este arquivo com senhas reais (adicione ao .gitignore)

# Exemplo de sourcing em um script:
# source "$(dirname "$0")/config.sh"
