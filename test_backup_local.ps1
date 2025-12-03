# ===================================================================
# TESTE LOCAL DO SCRIPT DE BACKUP (Windows PowerShell)
# Simula a execução do run_backup.sh para validar a lógica
# ===================================================================

Write-Host "=== TESTE LOCAL DO SCRIPT DE BACKUP ===" -ForegroundColor Cyan
Write-Host ""

# Simular diretórios
$backupSuite = "c:\Users\albac\Downloads\fdbank\teste servidor 29_10\consulta_cnpj\backup_suite"

# Verificar se os arquivos existem
$arquivos = @(
    "$backupSuite\backup_full_local.sh",
    "$backupSuite\send_backup_notification.php",
    "$backupSuite\run_backup.sh"
)

Write-Host "Verificando arquivos necessários:" -ForegroundColor Yellow
foreach ($arquivo in $arquivos) {
    if (Test-Path $arquivo) {
        Write-Host "✓ $arquivo existe" -ForegroundColor Green
    } else {
        Write-Host "✗ $arquivo NÃO ENCONTRADO" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== ESTRUTURA DO SCRIPT ===" -ForegroundColor Cyan
Write-Host "1. run_backup.sh define permissões (chmod +x)"
Write-Host "2. Executa backup_full_local.sh com redirecionamento para cron.log"
Write-Host "3. Captura código de saída"
Write-Host "4. Se sucesso (exit=0): chama PHP com parâmetro 'success'"
Write-Host "5. Se erro (exit≠0): chama PHP com parâmetro 'error'"
Write-Host "6. PHP envia email via PHPMailer"

Write-Host ""
Write-Host "=== TESTE DE ENVIO DE EMAIL ===" -ForegroundColor Cyan
Write-Host "Para testar o envio de email no servidor, execute via SSH:"
Write-Host "php /home/u640879529/backup_suite/send_backup_notification.php success /home/u640879529/backup_suite/cron.log" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== TESTE COMPLETO VIA SSH ===" -ForegroundColor Cyan
Write-Host "cd /home/u640879529/backup_suite" -ForegroundColor Yellow
Write-Host "/bin/bash run_backup.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "Depois verifique:"
Write-Host "- cat cron.log (ver log do backup)" -ForegroundColor Yellow
Write-Host "- ls -lh backups/ (ver arquivos gerados)" -ForegroundColor Yellow
Write-Host "- Seu email (verificar notificação)" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== CHECKLIST ANTES DE ATIVAR NO CRON ===" -ForegroundColor Cyan
Write-Host "1. Upload de todos os arquivos da pasta backup_suite"
Write-Host "2. Permissões 755 em: run_backup.sh e backup_full_local.sh"
Write-Host "3. Editar send_backup_notification.php com credenciais SMTP"
Write-Host "4. Testar manualmente via SSH (comando acima)"
Write-Host "5. Configurar cron: 0 3 * * 1 /bin/bash /home/u640879529/backup_suite/run_backup.sh"

Write-Host ""
Write-Host "Teste concluído!" -ForegroundColor Green
