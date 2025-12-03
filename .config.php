<?php
/**
 * Configuração Centralizada de Credenciais - BACKUP SUITE
 * 
 * Carrega variáveis do arquivo .env local ou do .env na raiz do servidor
 */

// Tentar carregar .env local primeiro (para desenvolvimento)
$envFile = __DIR__ . '/.env.local';

// Se não existir, usar .env da raiz do servidor (produção)
if (!file_exists($envFile)) {
    $envFile = '/home/u640879529/.env';
}

// Se ainda não existir, erro
if (!file_exists($envFile)) {
    die("ERRO: Arquivo .env não encontrado\n");
}

// Função para carregar variáveis do .env
function loadEnv($filePath) {
    if (!file_exists($filePath)) {
        return false;
    }
    
    $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) {
            continue;
        }
        
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            $value = trim($value, '"\'');
            
            putenv("$key=$value");
            $_ENV[$key] = $value;
            $_SERVER[$key] = $value;
        }
    }
    return true;
}

// Carregar as variáveis
if (!loadEnv($envFile)) {
    die("ERRO: Não foi possível carregar o arquivo .env\n");
}

echo "✓ .env carregado de: $envFile\n";

// Função helper
function env($key, $default = null) {
    $value = getenv($key);
    if ($value === false) {
        return $default;
    }
    return $value;
}

// Validação básica
$required = [
    'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASS',
    'DB_SECONDARY_HOST', 'DB_SECONDARY_NAME', 'DB_SECONDARY_USER', 'DB_SECONDARY_PASS',
    'AWS_BACKUP_REGION', 'AWS_BACKUP_BUCKET', 'AWS_BACKUP_ACCESS_KEY', 'AWS_BACKUP_SECRET_KEY',
    'SMTP_HOST', 'SMTP_USER', 'SMTP_PASS', 'EMAIL_TO'
];

$missing = [];
foreach ($required as $var) {
    if (empty(env($var))) {
        $missing[] = $var;
    }
}

if (!empty($missing)) {
    die("ERRO: Variáveis obrigatórias não definidas no .env: " . implode(', ', $missing) . "\n");
}

date_default_timezone_set(env('TIMEZONE', 'America/Sao_Paulo'));

echo "✓ Todas as variáveis obrigatórias carregadas\n";
echo "✓ Timezone: " . env('TIMEZONE', 'America/Sao_Paulo') . "\n";
echo "✓ DB Host: " . env('DB_HOST') . "\n";
echo "✓ DB Name: " . env('DB_NAME') . "\n";
echo "✓ AWS Bucket: " . env('AWS_BACKUP_BUCKET') . "\n";
echo "✓ SMTP Host: " . env('SMTP_HOST') . "\n";
?>
