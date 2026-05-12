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

$fileId = $data['id'] ?? null;
if (!$fileId) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'File ID required']));
}

// Получаем информацию о файле
$stmt = $pdo->prepare("SELECT * FROM files WHERE id = ?");
$stmt->execute([$fileId]);
$file = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$file) {
    http_response_code(404);
    die(json_encode(['status' => 'error', 'message' => 'File not found']));
}

// Проверка прав
if ($currentUser['is_admin'] != 1 && $file['user_id'] != $currentUser['id']) {
    http_response_code(403);
    die(json_encode(['status' => 'error', 'message' => 'Access denied']));
}

// Переключаем
$newVisibility = $file['is_public'] ? 0 : 1;
$stmt = $pdo->prepare("UPDATE files SET is_public = ? WHERE id = ?");
$stmt->execute([$newVisibility, $fileId]);

// Логирование изменения видимости
logAudit($pdo, $currentUser['id'], 'toggle_visibility', $fileId, $file['folder_id'], [
    'file_name' => $file['original_name'],
    'new_visibility' => $newVisibility ? 'public' : 'private'
]);

echo json_encode([
    'status' => 'success',
    'message' => 'Visibility toggled',
    'data' => ['id' => (int)$fileId, 'is_public' => $newVisibility]
]);