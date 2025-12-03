#!/bin/bash
# ============================================
# LIMPEZA: Remove backups antigos
# Mantém apenas conforme política de retenção
# ============================================

set -e

# CONFIGURAR ESTAS VARIÁVEIS
BACKUP_DIR="/backups/local/full"
INCREMENTAL_DIR="/backups/local/incremental"
LOG_DIR="/backups/local/logs"
BINLOG_DIR="/var/log/mysql"

mkdir -p "$LOG_DIR"

echo "[$(date)] Iniciando limpeza de backups antigos..." | tee -a "$LOG_DIR/cleanup.log"

# 1) Manter apenas últimos 4 full backups (4 semanas)
echo "[$(date)] Removendo full backups com > 28 dias..." | tee -a "$LOG_DIR/cleanup.log"
REMOVED=$(find $BACKUP_DIR -name "verify_production_FULL_*.sql.gz" -mtime +28 -delete -print | wc -l)
echo "[$(date)] Removidos: $REMOVED arquivos full antigos" | tee -a "$LOG_DIR/cleanup.log"

# 2) Manter binlogs por 14 dias
echo "[$(date)] Removendo binlogs com > 14 dias..." | tee -a "$LOG_DIR/cleanup.log"
REMOVED=$(find $BINLOG_DIR -name "mysql-bin.*" -not -name "*.index" -mtime +14 -delete -print 2>/dev/null | wc -l)
echo "[$(date)] Removidos: $REMOVED binlogs antigos" | tee -a "$LOG_DIR/cleanup.log"

# 3) Manter logs por 30 dias
echo "[$(date)] Removendo logs com > 30 dias..." | tee -a "$LOG_DIR/cleanup.log"
REMOVED=$(find $LOG_DIR -name "*.log" -mtime +30 -delete -print 2>/dev/null | wc -l)
echo "[$(date)] Removidos: $REMOVED arquivos de log antigos" | tee -a "$LOG_DIR/cleanup.log"

# 4) Verificar espaço em disco
USAGE=$(df /backups/local | tail -1 | awk '{print $5}' | sed 's/%//')
echo "[$(date)] Espaço utilizado em /backups/local: $USAGE%" | tee -a "$LOG_DIR/cleanup.log"

echo "[$(date)] ✓ Limpeza concluída" | tee -a "$LOG_DIR/cleanup.log"
