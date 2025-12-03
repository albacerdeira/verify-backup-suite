<?php
// Script para enviar notificação de backup por email usando PHPMailer
// Uso: php send_backup_notification.php "status" "mensagem" "detalhes"

// Carregar configurações do .env
require_once __DIR__ . '/../.config.php';

echo "Iniciando script de notificação...\n";

// Carregar PHPMailer
require_once __DIR__ . '/PHPMailer/Exception.php';
require_once __DIR__ . '/PHPMailer/PHPMailer.php';
require_once __DIR__ . '/PHPMailer/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

echo "PHPMailer carregado com sucesso\n";

if ($argc < 4) {
    die("Uso: php send_backup_notification.php status mensagem detalhes\n");
}

$status = $argv[1]; // "sucesso" ou "erro"
$mensagem = $argv[2];
$detalhes = $argv[3];

echo "Parâmetros recebidos: status=$status\n";

try {
    $mail = new PHPMailer(true);
    
    echo "Configurando SMTP...\n";
    
    // Configuração SMTP do .env
    $mail->isSMTP();
    $mail->Host = SMTP_HOST;
    $mail->SMTPAuth = true;
    $mail->Username = SMTP_USER;
    $mail->Password = SMTP_PASS;
    $mail->SMTPSecure = SMTP_ENCRYPTION;
    $mail->Port = SMTP_PORT;
    $mail->CharSet = 'UTF-8';
    $mail->SMTPDebug = 2; // Debug verboso
    
    echo "Configurando remetente e destinatário...\n";
    
    // Remetente e destinatário do .env
    $mail->setFrom(EMAIL_FROM, EMAIL_FROM_NAME);
    $mail->addAddress(EMAIL_TO, 'Administrador');
    
    // Definir assunto baseado no tipo e status
    if ($status === "sucesso") {
        $mail->Subject = "✓ " . $mensagem;
    } else {
        $mail->Subject = "✗ ERRO - " . $mensagem;
    }
    
    $mail->Body = "Notificação de Backup - " . date('d/m/Y H:i:s') . "\n\n";
    $mail->Body .= $mensagem . "\n\n";
    $mail->Body .= "Detalhes:\n" . $detalhes . "\n";
    
    echo "Enviando email...\n";
    $mail->send();
    echo "✓ Email enviado com sucesso\n";
} catch (Exception $e) {
    echo "✗ Falha ao enviar email: {$mail->ErrorInfo}\n";
    echo "Exceção: " . $e->getMessage() . "\n";
}
?>
