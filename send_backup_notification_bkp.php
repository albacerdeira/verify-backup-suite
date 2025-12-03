<?php
// ============================================
// ENVIO DE NOTIFICAÇÃO DE BACKUP
// Usa PHPMailer do diretório principal
// ============================================

// Carregar PHPMailer do diretório principal do projeto
require_once '/home/u640879529/domains/verify2b.com/public_html/kyc/PHPMailer/PHPMailer.php';
require_once '/home/u640879529/domains/verify2b.com/public_html/kyc/PHPMailer/SMTP.php';
require_once '/home/u640879529/domains/verify2b.com/public_html/kyc/PHPMailer/Exception.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Configurações de email (ajuste conforme seu SMTP)
$smtpHost = 'smtp.hostinger.com';  // ou seu servidor SMTP
$smtpPort = 465;//porta ssl
$smtpUser = 'noreply@verify2b.com';  // ajuste conforme necessário
$smtpPass = 'Bwc52915fgw329@!@!@';  // ajuste conforme necessário
$emailFrom = 'noreply@verify2b.com';
$emailFromName = 'Backup System';
$emailTo = 'alba.cerdeira@gmail.com';

// Receber parâmetros da linha de comando
$status = $argv[1] ?? 'unknown';  // 'success' ou 'error'
$logFile = $argv[2] ?? '/home/u640879529/backup_suite/cron.log';

// Preparar mensagem
if ($status === 'success') {
    $subject = '✓ Backup MySQL Concluído com Sucesso';
    $message = "
        <h2 style='color: green;'>✓ Backup Concluído com Sucesso</h2>
        <p>O backup do banco de dados <strong>u640879529_kyc</strong> foi concluído com sucesso.</p>
        <p><strong>Data/Hora:</strong> " . date('d/m/Y H:i:s') . "</p>
        <p><strong>Log:</strong> {$logFile}</p>
        <hr>
        <p style='font-size: 12px; color: #666;'>Backup automático via cron - Hostinger</p>
    ";
} else {
    $subject = '✗ ERRO: Falha no Backup MySQL';
    $message = "
        <h2 style='color: red;'>✗ ERRO no Backup</h2>
        <p><strong>ATENÇÃO:</strong> O backup do banco de dados <strong>u640879529_kyc</strong> falhou.</p>
        <p><strong>Data/Hora:</strong> " . date('d/m/Y H:i:s') . "</p>
        <p><strong>Ação necessária:</strong> Verifique urgentemente o log em {$logFile}</p>
        <hr>
        <p style='font-size: 12px; color: #666;'>Backup automático via cron - Hostinger</p>
    ";
}

// Enviar email
$mail = new PHPMailer(true);

try {
    // Configurações do servidor
    $mail->isSMTP();
    $mail->Host       = $smtpHost;
    $mail->SMTPAuth   = true;
    $mail->Username   = $smtpUser;
    $mail->Password   = $smtpPass;
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = $smtpPort;
    $mail->CharSet    = 'UTF-8';

    // Remetente e destinatário
    $mail->setFrom($emailFrom, $emailFromName);
    $mail->addAddress($emailTo);

    // Conteúdo
    $mail->isHTML(true);
    $mail->Subject = $subject;
    $mail->Body    = $message;

    $mail->send();
    echo "Email enviado com sucesso para {$emailTo}\n";
} catch (Exception $e) {
    echo "Erro ao enviar email: {$mail->ErrorInfo}\n";
    exit(1);
}
?>
