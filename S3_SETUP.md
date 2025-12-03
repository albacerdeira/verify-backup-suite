# Configuração do Upload S3

## Pré-requisitos

1. **Criar bucket S3 na AWS:**
   - Acesse: https://s3.console.aws.amazon.com/
   - Clique em "Create bucket"
   - Nome sugerido: `verify-mysql-backups`
   - Região: `us-east-1` (ou `sa-east-1` para Brasil)
   - Mantenha bloqueio de acesso público
   - Clique em "Create bucket"

2. **Baixar AWS CLI no Windows e enviar via FTP:**
   
   **Execute no PowerShell:**
   ```powershell
   cd "C:\Users\albac\Downloads\fdbank\teste servidor 29_10\consulta_cnpj\backup_suite"
   .\download_aws_cli.ps1
   ```
   
   **Envie via FTP para Hostinger:**
   - Local: `backup_suite\aws_cli_linux\aws\` (pasta completa)
   - Destino: `/home/u640879529/backup_suite/aws/`
   
   **Instale via SSH no servidor:**
   ```bash
   ssh u640879529@br-asc-web1893.main-hosting.eu
   cd ~/backup_suite
   ./aws/install --bin-dir ~/.local/bin --install-dir ~/.local/aws-cli
   ```
   
   **Verifique a instalação:**
   ```bash
   ~/.local/bin/aws --version
   # Deve mostrar: aws-cli/2.x.x Python/3.x.x Linux/x86_64
   ```

## Ativação

1. **Edite o arquivo `upload_to_s3.sh`:**
   - Linha 11: Altere `S3_BUCKET` para o nome real do seu bucket
   
2. **Descomente as linhas no `backup_full_local.sh`:**
   ```bash
   # Remova o # das linhas 76-77:
   echo "[$(date)] Iniciando upload para S3..." | tee -a $LOG_FILE
   /bin/bash /home/u640879529/backup_suite/upload_to_s3.sh
   ```

3. **Dê permissão de execução:**
   ```bash
   chmod 755 /home/u640879529/backup_suite/upload_to_s3.sh
   ```

4. **Teste manualmente:**
   ```bash
   /bin/bash /home/u640879529/backup_suite/upload_to_s3.sh
   ```

## Credenciais AWS

Já configuradas no script:
- Access Key: `AKIAT4CGSMKPWOZNYWOU`
- Region: `us-east-1`

## Retenção

Para configurar exclusão automática de backups antigos no S3:
1. Acesse o bucket no console AWS
2. Vá em "Management" → "Lifecycle rules"
3. Crie regra para expirar objetos após 90 dias (ou o período desejado)

## Custos Estimados

- Armazenamento: ~$0.0125/GB/mês (STANDARD_IA)
- Backup de 50MB = ~$0.62/ano
- Transfer OUT: Grátis até 100GB/mês

## Segurança

✅ Bucket privado (não acessível publicamente)  
✅ Credenciais AWS com permissão mínima (S3 PutObject/ListBucket)  
✅ Backups com hash SHA256 para integridade  
