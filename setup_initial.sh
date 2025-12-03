#!/bin/bash
# ============================================
# SETUP INICIAL - Backup Suite
# Execute uma única vez para preparar ambiente
# ============================================

set -e

echo "╔════════════════════════════════════════╗"
echo "║  Backup Suite - Setup Inicial          ║"
echo "║  VERIFY Backup & Replicação            ║"
echo "╚════════════════════════════════════════╝"
echo ""

SUITE_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) Criar estrutura de diretórios
echo "[1/5] Criando diretórios..."
mkdir -p /backups/local/{full,incremental,binlog,logs,tmp}
mkdir -p /var/log/mysql
echo "✓ Diretórios criados"

# 2) Ajustar permissões
echo "[2/5] Configurando permissões..."
chmod 755 $SUITE_DIR/*.sh
chmod 600 $SUITE_DIR/config.sh
chmod 700 /backups/local
echo "✓ Permissões configuradas"

# 3) Instalar dependências
echo "[3/5] Verificando dependências..."
MISSING=""
for cmd in mysql mysqldump gzip sha256sum mail; do
    if ! command -v $cmd &> /dev/null; then
        MISSING+="$cmd "
    fi
done

if [ -n "$MISSING" ]; then
    echo "⚠️  Pacotes faltando: $MISSING"
    echo "Instale com: sudo apt-get install -y mysql-client mailutils"
    read -p "Continuar mesmo assim? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
else
    echo "✓ Todas as dependências encontradas"
fi

# 4) Configurar arquivo de credenciais
echo "[4/5] Configurando credenciais..."
if [ ! -f "$SUITE_DIR/config.sh" ]; then
    echo "⚠️  Arquivo config.sh não encontrado!"
    exit 1
fi

echo ""
echo "Por favor, edite as seguintes variáveis em config.sh:"
echo "  - DB_HOST, DB_USER, DB_PASS"
echo "  - S3_BUCKET, AWS_PROFILE"
echo "  - ALERT_EMAIL"
echo ""
read -p "Deseja abrir config.sh agora? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    nano $SUITE_DIR/config.sh
fi

# 5) Agendar cron jobs
echo "[5/5] Agendando cron jobs..."
bash $SUITE_DIR/setup_cron.sh

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✓ Setup Concluído!                   ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Próximos passos:"
echo "  1) Testar backup manualmente:"
echo "     bash $SUITE_DIR/backup_full_local.sh"
echo ""
echo "  2) Verificar status:"
echo "     cat $SUITE_DIR/status.json | jq '.'"
echo ""
echo "  3) Ver dashboard:"
echo "     open $SUITE_DIR/dashboard.html"
echo ""
echo "  4) Monitorar logs:"
echo "     tail -f /backups/local/logs/backup_full_*.log"
echo ""
