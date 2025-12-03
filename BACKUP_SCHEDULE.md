# Agendamento de Backups - Verify2B

## Configuração Atual

### Backup Semanal Completo
- **Script**: `backup_full_local.sh`
- **Frequência**: Toda segunda-feira às 3:00 AM
- **Cron**: `0 3 * * 1 /bin/bash /home/u640879529/backup_suite/backup_full_local.sh`
- **Inclui**:
  - Dump completo do banco u640879529_kyc
  - Compressão gzip
  - Hash SHA256
  - Replicação para u640879529_kyc_back_fc
  - Upload para S3 (verify-mysql-backups)
  - Email de confirmação
- **Retenção**: 28 dias local

### Backup Incremental Diário (NOVO)
- **Script**: `backup_incremental_local.sh`
- **Frequência**: 4x por dia (a cada 6 horas) - exceto segunda
- **Horários**: 03:00, 09:00, 15:00, 21:00
- **Cron**: 
  ```
  0 3,9,15,21 * * 2-7 /bin/bash /home/u640879529/backup_suite/backup_incremental_local.sh
  ```
- **Inclui**:
  - Dump leve das alterações
  - Compressão gzip
  - Hash SHA256
  - Email de confirmação
- **Retenção**: 7 dias
- **Risco máximo de perda**: 6 horas de dados

## Como Configurar o Backup Diário

### 1. Enviar arquivo via FTP
- Local: `backup_suite\backup_incremental_local.sh`
- Destino: `/home/u640879529/backup_suite/backup_incremental_local.sh`

### 2. Dar permissão de execução (via SSH)
```bash
chmod +x /home/u640879529/backup_suite/backup_incremental_local.sh
```

### 3. Testar manualmente
```bash
/bin/bash /home/u640879529/backup_suite/backup_incremental_local.sh
```

### 4. Adicionar ao cron (Hostinger painel ou SSH)

**Via Painel Hostinger:**
1. Acesse: hPanel → Advanced → Cron Jobs
2. Clique em "Create Cron Job"
3. Configure:
   - **Type**: Custom
   - **Minute**: 0
   - **Hour**: 3,9,15,21 (separado por vírgula)
   - **Day**: * (todos)
   - **Month**: * (todos)
   - **Weekday**: 2-7 (terça a domingo)
   - **Command**: `/bin/bash /home/u640879529/backup_suite/backup_incremental_local.sh`
4. Salvar

**Via SSH (crontab -e):**
```bash
crontab -e
```
Adicionar linha:
```
0 3,9,15,21 * * 2-7 /bin/bash /home/u640879529/backup_suite/backup_incremental_local.sh
```

## Calendário de Backups

| Dia/Hora  | 03:00     | 09:00 | 15:00 | 21:00 |
|-----------|-----------|-------|-------|-------|
| Segunda   | **FULL**  | Inc.  | Inc.  | Inc.  |
| Terça     | Inc.      | Inc.  | Inc.  | Inc.  |
| Quarta    | Inc.      | Inc.  | Inc.  | Inc.  |
| Quinta    | Inc.      | Inc.  | Inc.  | Inc.  |
| Sexta     | Inc.      | Inc.  | Inc.  | Inc.  |
| Sábado    | Inc.      | Inc.  | Inc.  | Inc.  |
| Domingo   | Inc.      | Inc.  | Inc.  | Inc.  |

**Legenda:**
- **FULL**: Backup completo + Replicação DB + Upload S3 (segunda 3:00)
- **Inc.**: Backup incremental (4x/dia, a cada 6h)

**Total de backups por semana:**
- 1 backup FULL (segunda 3:00)
- 27 backups incrementais (4x/dia × 7 dias - 1 FULL)

## Estrutura de Arquivos

```
/home/u640879529/backup_suite/
├── backups/
│   ├── backup_u640879529_kyc_2025-12-02_20-04-01.sql.gz    # Backup FULL semanal
│   ├── backup_u640879529_kyc_2025-12-02_20-04-01.sql.gz.sha256
│   └── incremental/                                         # Backups diários
│       ├── incremental_20251203_023001.sql.gz
│       ├── incremental_20251203_023001.sql.gz.sha256
│       ├── incremental_20251204_023001.sql.gz
│       └── ...
├── logs/
│   ├── backup_full_20251202_200401.log
│   ├── backup_incremental_20251203_023001.log
│   └── s3_upload_20251202_200413.log
└── scripts/
    ├── backup_full_local.sh
    ├── backup_incremental_local.sh
    ├── upload_to_s3.sh
    ├── restore_to_secondary.sh
    └── send_backup_notification.php
```

## Notificações por Email

Você receberá emails para:
- ✅ Backup FULL semanal concluído
- ✅ Replicação para banco secundário
- ✅ Upload S3 concluído
- ✅ Backup incremental diário concluído
- ❌ Qualquer erro nos processos

## Monitoramento

### Verificar últimos backups
```bash
# Full backups
ls -lh /home/u640879529/backup_suite/backups/*.sql.gz

# Incrementais
ls -lh /home/u640879529/backup_suite/backups/incremental/*.sql.gz
```

### Ver logs recentes
```bash
# Últimas linhas do log FULL
tail -50 /home/u640879529/backup_suite/logs/backup_full_*.log | tail -50

# Últimas linhas do log incremental
## Política de Retenção

| Tipo        | Retenção Local | Retenção S3      | Cleanup Automático | Frequência    |
|-------------|----------------|------------------|--------------------|---------------|
| FULL        | 28 dias        | 90 dias*         | Sim (backup script)| 1x/semana     |
| Incremental | 7 dias         | Não enviado      | Sim (incremental)  | 4x/dia (6h)   |

*Configurar Lifecycle Rule no S3 (ver S3_SETUP.md)

**Espaço estimado (por semana):**
- Backup FULL: ~56MB × 1 = 56MB
- Backups incrementais: ~4KB × 27 = ~108KB
- **Total**: ~56MB/semana (muito otimizado!)
## Política de Retenção

| Tipo        | Retenção Local | Retenção S3      | Cleanup Automático |
|-------------|----------------|------------------|--------------------|
| FULL        | 28 dias        | 90 dias*         | Sim (backup script)|
| Incremental | 7 dias         | Não enviado      | Sim (incremental)  |

*Configurar Lifecycle Rule no S3 (ver S3_SETUP.md)

## Restauração

### De backup FULL
```bash
# Descompactar
gunzip -c /home/u640879529/backup_suite/backups/backup_u640879529_kyc_2025-12-02_20-04-01.sql.gz > restore.sql

# Restaurar
mysql -h localhost -u u640879529_kyc -p u640879529_kyc < restore.sql
```

### De backup Incremental
```bash
# Similar ao FULL
gunzip -c /home/u640879529/backup_suite/backups/incremental/incremental_20251203_023001.sql.gz > restore.sql
mysql -h localhost -u u640879529_kyc -p u640879529_kyc < restore.sql
```

## Troubleshooting

### Backup incremental não está rodando
1. Verificar permissões: `ls -l /home/u640879529/backup_suite/backup_incremental_local.sh`
2. Deve mostrar: `-rwxr-xr-x` (executável)
3. Se não: `chmod +x /home/u640879529/backup_suite/backup_incremental_local.sh`

### Email não está chegando
1. Verificar log: `tail -100 /home/u640879529/backup_suite/logs/backup_incremental_*.log`
2. Buscar por erros de PHPMailer

### Espaço em disco cheio
1. Verificar uso: `du -sh /home/u640879529/backup_suite/backups/*`
2. Limpar manualmente backups antigos:
```bash
find /home/u640879529/backup_suite/backups/incremental -name "*.gz" -mtime +3 -delete
```

## Próximos Passos Sugeridos

1. ✅ Backup incremental diário (IMPLEMENTADO)
2. ✅ Monitoramento automatizado (IMPLEMENTADO)
3. ⏳ S3 Lifecycle rules (reduzir custos)
4. ⏳ Point-in-Time Recovery (PITR)

---

## Monitoramento Automático (NOVO)

### Configurar Monitoramento

**1. Enviar arquivo via FTP:**
- `monitor_backup_health.sh` → `/home/u640879529/backup_suite/`

**2. Dar permissão (via SSH):**
```bash
chmod +x /home/u640879529/backup_suite/monitor_backup_health.sh
```

**3. Testar manualmente:**
```bash
/bin/bash /home/u640879529/backup_suite/monitor_backup_health.sh
```

**4. Agendar no cron (a cada 30 minutos):**

Via Painel Hostinger:
- Type: Custom
- Minute: `*/30`
- Hour: `*`
- Day: `*`
- Month: `*`
- Weekday: `*`
- Command: `/bin/bash /home/u640879529/backup_suite/monitor_backup_health.sh`

Via SSH:
```bash
crontab -e
```
Adicionar:
```
*/30 * * * * /bin/bash /home/u640879529/backup_suite/monitor_backup_health.sh
```

### O que o Monitor Verifica

✅ **Último Backup FULL**
- Alerta se > 7 dias
- Verifica integridade SHA256

✅ **Último Backup Incremental**  
- Alerta se > 24 horas

✅ **Espaço em Disco**
- Crítico: < 1GB disponível
- Aviso: > 85% usado

✅ **Contagem de Backups**
- FULL e incrementais

✅ **Status JSON**
- Gera `/home/u640879529/backup_suite/status.json`

### Notificações

Você receberá email **APENAS se houver problemas**:
- 🚨 **Alertas Críticos** - Assunto: "🚨 Monitoramento: ALERTAS Detectados"
- ⚠️ **Avisos** - Assunto: "⚠ Monitoramento: Avisos"

Se está tudo OK, **não recebe email** (sem spam!)

### Ver Status em Tempo Real

```bash
# Ver JSON de status
cat /home/u640879529/backup_suite/status.json

# Ver último log
tail -50 /home/u640879529/backup_suite/logs/monitor_*.log | tail -50
```
