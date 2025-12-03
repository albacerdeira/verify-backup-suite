<?php
// ============================================
// FULL BACKUP LOCAL (SEMANAL) - PHP
// Dump completo do banco com compressão
// ============================================

// Configurações do banco
$dbHost = 'localhost';
$dbUser = 'u640879529_kyc';
$dbPass = 'Bwc52915fgw329@!!@';
$dbName = 'u640879529_kyc';

// Diretórios
$backupDir = '/home/u640879529/backup_suite/backups';
$logDir    = '/home/u640879529/backup_suite/logs';

// Garantir diretórios
if (!is_dir($backupDir)) mkdir($backupDir, 0755, true);
if (!is_dir($logDir)) mkdir($logDir, 0755, true);

$timestamp = date('Ymd_His');
$dumpFile  = "{$backupDir}/{$dbName}_FULL_{$timestamp}.sql";
$logFile   = "{$logDir}/backup_full_{$timestamp}.log";

// Verificar se exec está disponível
$disabledFunctions = explode(',', ini_get('disable_functions'));
if (in_array('exec', $disabledFunctions)) {
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] ERRO: função exec() está desabilitada no PHP\n", FILE_APPEND);
    die("ERRO: função exec() desabilitada. Use o script bash (.sh) via cron.\n");
}

// Tentar encontrar mysqldump
$mysqldumpPath = trim(shell_exec('which mysqldump 2>/dev/null') ?: 'mysqldump');
file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Caminho mysqldump: {$mysqldumpPath}\n", FILE_APPEND);

// Comando mysqldump
$cmd = "{$mysqldumpPath} -h {$dbHost} -u {$dbUser} -p'{$dbPass}' --single-transaction --quick --lock-tables=false {$dbName} > {$dumpFile} 2>> {$logFile}";

// Executar backup
file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Iniciando backup...\n", FILE_APPEND);
file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Comando: mysqldump -h {$dbHost} -u {$dbUser} -p*** ...\n", FILE_APPEND);
exec($cmd, $output, $result);
file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] mysqldump exit code: {$result}\n", FILE_APPEND);
if (!empty($output)) {
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Output: ".implode("\n", $output)."\n", FILE_APPEND);
}

if ($result === 0) {
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Dump criado com sucesso\n", FILE_APPEND);
    
    // Compactar
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Compactando dump...\n", FILE_APPEND);
    exec("gzip {$dumpFile}", $output, $zipResult);
    $dumpFileGz = "{$dumpFile}.gz";
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Dump comprimido (exit code: {$zipResult})\n", FILE_APPEND);
    
    // Hash
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Gerando hash...\n", FILE_APPEND);
    exec("sha256sum {$dumpFileGz} > {$dumpFileGz}.sha256");
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Hash gerado\n", FILE_APPEND);
    
    // Tamanho
    $size = filesize($dumpFileGz);
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Arquivo comprimido: {$dumpFileGz} (".round($size/1024/1024,2)." MB)\n", FILE_APPEND);
    
    // Remover backups antigos
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Removendo backups antigos (>28 dias)...\n", FILE_APPEND);
    exec("find {$backupDir} -name '{$dbName}_FULL_*.sql.gz' -mtime +28 -delete");
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] Backups antigos removidos\n", FILE_APPEND);
    
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] ✓ Backup full concluído com sucesso\n", FILE_APPEND);
    echo "✓ SUCESSO: {$dumpFileGz} (".round($size/1024/1024,2)." MB)\n";
} else {
    file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] ✗ ERRO ao fazer dump (exit code: {$result})\n", FILE_APPEND);
    echo "✗ ERRO: Falha ao fazer backup. Verifique o log: {$logFile}\n";
}
?>
