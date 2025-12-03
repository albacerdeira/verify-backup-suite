# Script para baixar AWS CLI Linux no Windows e preparar para upload via FTP
# Versão: 1.0
# Data: 2025-12-02

Write-Host "=== Download AWS CLI para Linux ===" -ForegroundColor Cyan

# Definir diretório de download
$downloadDir = "$PSScriptRoot\aws_cli_linux"
$zipFile = "$downloadDir\awscliv2.zip"

# Criar diretório se não existir
if (-not (Test-Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
    Write-Host "[OK] Diretório criado: $downloadDir" -ForegroundColor Green
}

# Baixar AWS CLI
Write-Host "[INFO] Baixando AWS CLI para Linux x86_64..." -ForegroundColor Yellow
$url = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

try {
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Write-Host "[OK] Download concluído: $(Get-Item $zipFile | Select-Object -ExpandProperty Length) bytes" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Falha no download: $_" -ForegroundColor Red
    exit 1
}

# Extrair arquivo
Write-Host "[INFO] Extraindo arquivos..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $zipFile -DestinationPath $downloadDir -Force
    Write-Host "[OK] Arquivos extraídos em: $downloadDir\aws" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Falha na extração: $_" -ForegroundColor Red
    exit 1
}

# Exibir tamanho
$awsFolder = "$downloadDir\aws"
$totalSize = (Get-ChildItem -Path $awsFolder -Recurse | Measure-Object -Property Length -Sum).Sum
$sizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host ""
Write-Host "=== PROXIMOS PASSOS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Pasta AWS CLI preparada: $awsFolder" -ForegroundColor White
Write-Host "   Tamanho total: $sizeMB MB" -ForegroundColor White
Write-Host ""
Write-Host "2. Enviar via FTP para Hostinger:" -ForegroundColor Yellow
Write-Host "   Local: $awsFolder" -ForegroundColor White
Write-Host "   Destino: /home/u640879529/backup_suite/aws/" -ForegroundColor White
Write-Host ""
Write-Host "3. Apos upload, execute no servidor via SSH:" -ForegroundColor Yellow
Write-Host "   cd /home/u640879529/backup_suite" -ForegroundColor White
Write-Host "   ./aws/install --bin-dir /home/u640879529/.local/bin --install-dir /home/u640879529/.local/aws-cli" -ForegroundColor White
Write-Host ""
Write-Host "4. Script upload_to_s3.sh ja esta configurado!" -ForegroundColor Yellow
Write-Host "   Teste com: /bin/bash /home/u640879529/backup_suite/upload_to_s3.sh" -ForegroundColor White
Write-Host ""
