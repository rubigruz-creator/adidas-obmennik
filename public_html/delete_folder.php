
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
$force = ($data['force'] ?? false) == true;

if (!$folderId) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'Folder ID required']));
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

// Сохраняем данные для лога
$folderName = $folder['name'];

// Если force=true — перемещаем файлы в родительскую папку
if ($force) {
    $stmt = $pdo->prepare("UPDATE files SET folder_id = ? WHERE folder_id = ?");
    $stmt->execute([$folder['parent_id'], $folderId]);
}

// Удаляем подпапки (рекурсивно не делаем, просто привязываем к родителю)
$stmt = $pdo->prepare("UPDATE folders SET parent_id = ? WHERE parent_id = ?");
$stmt->execute([$folder['parent_id'], $folderId]);

// Удаляем папку
$stmt = $pdo->prepare("DELETE FROM folders WHERE id = ?");
$stmt->execute([$folderId]);

// Логирование удаления папки
logAudit($pdo, $currentUser['id'], 'delete_folder', null, $folderId, [
    'folder_name' => $folderName
]);

echo json_encode(['status' => 'success', 'message' => 'Folder deleted']);