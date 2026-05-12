<?php
header('Content-Type: application/json');

require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/log_action.php';

$host = 'localhost';
$db   = 'avito_shop';
$user = 'api_user';
$pass = 'StrongPass123!';

$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
$pdo = new PDO($dsn, $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$currentUser = authenticate($pdo);

// Парсим JSON из тела запроса
$input = json_decode(file_get_contents('php://input'), true);

// Получаем ID файла из GET, POST или JSON
$fileId = $_GET['id'] ?? $_POST['id'] ?? $input['id'] ?? null;
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

// Проверка прав: админ или владелец
if ($currentUser['is_admin'] != 1 && $file['user_id'] != $currentUser['id']) {
    http_response_code(403);
    die(json_encode(['status' => 'error', 'message' => 'Access denied']));
}

// Сохраняем данные для лога перед удалением
$fileName = $file['original_name'];
$folderId = $file['folder_id'];

// Удаляем физический файл
$filePath = __DIR__ . '/files/' . $file['stored_name'];
if (file_exists($filePath)) {
    unlink($filePath);
}

// Удаляем запись из БД
$stmt = $pdo->prepare("DELETE FROM files WHERE id = ?");
$stmt->execute([$fileId]);

// Логирование удаления файла
logAudit($pdo, $currentUser['id'], 'delete', $fileId, $folderId, [
    'file_name' => $fileName
]);

echo json_encode(['status' => 'success', 'message' => 'File deleted']);