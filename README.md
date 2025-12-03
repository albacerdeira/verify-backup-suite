# Backup Suite - VERIFY

Sistema completo de backup seguro, replicação MySQL, monitoramento e disaster recovery.

## 📁 Arquivos

### Scripts Principais
- `backup_full_local.sh` — Backup completo semanal (comprimido com gzip)
- `backup_incremental_local.sh` — Backup incremental diário via binlog
- `backup_upload_s3.sh` — Upload backup para AWS S3 (geo-redundante)
- `monitor_backup_health.sh` — Monitoramento em tempo real com alertas
- `failover_slave_to_master.sh` — Promove slave para master (emergência)
- `pitr_restore.sh` — Point-in-time recovery (restaura para data/hora específica)
- `cleanup_old_backups.sh` — Remove backups conforme política de retenção
- `backup_air_gapped.sh` — Cópia offline em disco externo (ransomware-proof)

### Utilitários
- `setup_cron.sh` — Agenda todos os scripts automaticamente
- `config.sh` — Configuração centralizada (credenciais, paths)
- `dashboard.html` — Dashboard visual (Bootstrap 5)
- `status.json` — Status atualizado pelo monitor

## 🚀 Quick Start

### 1) Configurar
```bash
# Editar credenciais e paths
nano config.sh

# Preencher:
# - DB_HOST, DB_USER, DB_PASS
# - S3_BUCKET, AWS_PROFILE
# - ALERT_EMAIL
# - Outros paths conforme infraestrutura
```

### 2) Agendar Backups
```bash
# Esto agenda todos os cron jobs automaticamente
bash setup_cron.sh

# Verificar agendamento
crontab -l
```

### 3) Monitorar
```bash
# Ver status em JSON
cat status.json

# Abrir dashboard visual
open dashboard.html
# (ou via navegador: http://seu-servidor/backup_suite/dashboard.html)
```

## 📊 Agenda Padrão (após setup_cron.sh)

| Horário | Tarefa |
|---------|--------|
| Dom 02:00 | Full backup (dump completo) |
| Diário 02:30 | Incremental backup (binlog) |
| Diário 03:00 | Upload S3 (remoto) |
| Seg 04:00 | Limpeza (remove antigos) |
| A cada 30min | Monitoramento (atualiza status) |

## 🔧 Scripts de Emergência (Manual)

### Failover: Master caiu
```bash
bash failover_slave_to_master.sh
# Promove slave para master em < 1 minuto
```

### PITR: Dados deletados acidentalmente
```bash
# Editar script com hora do acidente
nano pitr_restore.sh
# Alterar: RESTORE_TIME="2025-12-01 14:30:00"

bash pitr_restore.sh
# Restaura para hora específica em DB temporário
```

### Air-gapped: Proteção anti-ransomware
```bash
# 1) Conectar disco externo
# 2) Montar: sudo mount /dev/sdbX /mnt/backup-externo
# 3) Editar config.sh com EXTERNAL_DISK correto
# 4) Executar:
bash backup_air_gapped.sh
# 5) Desconectar disco (proteção máxima)
```

## 📈 Monitoramento

### Ver Status em Tempo Real
```bash
# Executar monitoramento manualmente
bash monitor_backup_health.sh

# Ver resultado em JSON
cat status.json | jq '.'

# Ou via dashboard HTML
open dashboard.html
```

### Alertas por Email
- Configurar `ALERT_EMAIL` em `config.sh`
- Monitor envia alertas se:
  - Replicação falha
  - Backup > 36 horas
  - Disco > 80%

## 🔐 Segurança

### Permissões
```bash
# Arquivos sensíveis devem ter permissão 600
chmod 600 config.sh
chmod 600 status.json

# Scripts com permissão 755
chmod 755 *.sh

# Diretório de backup protegido
chmod 700 /backups/local
```

### Criptografia
- S3: AES-256 (padrão AWS)
- Air-gapped: GPG AES-256 (opcional, editável em config.sh)
- Trânsito: HTTPS/TLS

### Proteção Ransomware
- ✅ Versioning em S3
- ✅ Object Lock (imutável 15 anos)
- ✅ Air-gapped offline (desconectado)
- ✅ Backup em conta AWS separada (recomendado)

## 📋 Troubleshooting

### "Connection refused" no DB
```bash
# Verificar se MySQL está rodando
sudo systemctl status mysql

# Verificar credenciais em config.sh
# Testar manualmente:
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "SELECT 1;"
```

### "No such file or directory" em S3
```bash
# Verificar AWS CLI configurado
aws configure --profile default
aws s3 ls  # Deve listar buckets

# Verificar S3_BUCKET em config.sh
aws s3 ls s3://verify-backups-production/
```

### Disco cheio
```bash
# Executar limpeza manual
bash cleanup_old_backups.sh

# Ou aumentar retenção (em config.sh)
RETAIN_FULL_BACKUP=60  # dias
```

## 🧪 Testar Recuperação

### Teste Mensal: Failover
```bash
# 1) Parar master (simular falha)
sudo systemctl stop mysql

# 2) Executar failover
bash failover_slave_to_master.sh

# 3) Verificar slave agora é master
mysql -h SLAVE_IP -u root -p -e "SHOW MASTER STATUS\G"

# 4) Restaurar master
sudo systemctl start mysql
```

### Teste Trimestral: PITR
```bash
# 1) Fazer INSERT de dados teste
mysql -e "INSERT INTO verify_production.usuarios (email) VALUES ('teste@pitr.com');"

# 2) Executar PITR
bash pitr_restore.sh

# 3) Verificar dados em DB restore: verify_production_restore

# 4) Limpar: DROP DATABASE verify_production_restore;
```

## 📚 Documentação Completa

Consulte arquivo principal:
```
../BACKUP_REPLICATION_DISASTER_RECOVERY_PLAN.md
```

Para detalhes de:
- Replicação MySQL Master-Slave
- Arquitetura 3-2-1
- Plano de Disaster Recovery
- Cenários de falha e recuperação

## 💡 Dicas

1. **Teste regularmente:** Backups sem teste não valem nada
2. **Documente procedures:** Guarde runbooks impressos
3. **Monitore alertas:** Configure email para falhas
4. **Backup do backup:** Faça cópia de backups críticos offline
5. **Rotação de credenciais:** Troque senhas a cada 90 dias

## ⚠️ Importante

- **NÃO** commitar `config.sh` com senhas reais
- Adicione ao `.gitignore`: `backup_suite/config.sh`
- Proteja permissões: `chmod 600 config.sh`
- Teste recuperação antes de contar com backups
- Manter cópia de credenciais em local seguro (password manager)

---

**Última atualização:** 01/12/2025  
**Versão:** 1.0  
**Status:** Production-ready
