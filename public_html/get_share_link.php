<?php
header('Content-Type: application/json');

require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/json_input.php';
require_once __DIR__ . '/log_action.php';

$host = 'localhost';
$db   = 'avito_shop';
$user = 'api_user';
$pass = 'StrongPass123!';

$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
$pdo = new PDO($dsn, $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$currentUser = authenticate($pdo);
$data = getInputData();

if (!isset($data['file_id'])) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'file_id required']);
    exit;
}

$fileId = (int)$data['file_id'];

// Получаем файл из БД
$stmt = $pdo->prepare("SELECT * FROM files WHERE id = ?");
$stmt->execute([$fileId]);
$file = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$file) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'File not found']);
    exit;
}

// Проверяем право на создание ссылки: владелец файла или админ
if ($file['user_id'] != $currentUser['id'] && $currentUser['is_admin'] != 1) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Access denied']);
    exit;
}

// Генерируем случайный токен
$token = bin2hex(random_bytes(16));

// Срок действия ссылки – 7 дней
$expiresAt = date('Y-m-d H:i:s', strtotime('+7 days'));

$insert = $pdo->prepare("
    INSERT INTO share_links (file_id, token, created_by, expires_at)
    VALUES (?, ?, ?, ?)
");
$insert->execute([$fileId, $token, $currentUser['id'], $expiresAt]);

$shareUrl = 'https://gazonbaza.ru/public_download.php?token=' . $token;

// Логирование создания ссылки
logAudit($pdo, $currentUser['id'], 'share', $fileId, $file['folder_id'], [
    'file_name' => $file['original_name']
]);

echo json_encode([
    'status' => 'success',
    'share_url' => $shareUrl
]);