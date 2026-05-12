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

$folderId = $data['id'] ?? null;
$newName = $data['new_name'] ?? '';

if (!$folderId || empty($newName)) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'Folder ID and new name required']));
}

// Проверяем папку
$stmt = $pdo->prepare("SELECT * FROM folders WHERE id = ?");
$stmt->execute([$folderId]);
$folder = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$folder) {
    http_response_code(404);
    die(json_encode(['status' => 'error', 'message' => 'Folder not found']));
}

// Проверка прав
if ($currentUser['is_admin'] != 1 && $folder['user_id'] != $currentUser['id']) {
    http_response_code(403);
    die(json_encode(['status' => 'error', 'message' => 'Access denied']));
}

// Сохраняем старое имя для лога
$oldName = $folder['name'];

$stmt = $pdo->prepare("UPDATE folders SET name = ? WHERE id = ?");
$stmt->execute([$newName, $folderId]);

// Логирование переименования папки
logAudit($pdo, $currentUser['id'], 'rename_folder', null, $folderId, [
    'old_name' => $oldName,
    'new_name' => $newName
]);

echo json_encode(['status' => 'success', 'message' => 'Folder renamed']);