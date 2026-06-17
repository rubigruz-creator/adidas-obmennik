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

$fileId = $data['file_id'] ?? null;
$folderId = $data['folder_id'] ?? null;

if (!$fileId) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'File ID required']));
}

// Проверяем файл
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

// Сохраняем данные для лога
$fileName = $file['original_name'];
$fromFolderId = $file['folder_id'];

// Если указана папка — проверяем её и получаем имя
$toFolderName = null;
if ($folderId !== null && $folderId !== '') {
    $stmt = $pdo->prepare("SELECT id, name FROM folders WHERE id = ?");
    $stmt->execute([$folderId]);
    $targetFolder = $stmt->fetch();
    if (!$targetFolder) {
        http_response_code(404);
        die(json_encode(['status' => 'error', 'message' => 'Folder not found']));
    }
    $toFolderName = $targetFolder['name'];
}

// Получаем имя исходной папки
$fromFolderName = null;
if ($fromFolderId) {
    $stmt = $pdo->prepare("SELECT name FROM folders WHERE id = ?");
    $stmt->execute([$fromFolderId]);
    $fromFolder = $stmt->fetch();
    $fromFolderName = $fromFolder ? $fromFolder['name'] : null;
}

// Перемещаем
$folderId = $folderId === '' || $folderId === null ? null : (int)$folderId;
$stmt = $pdo->prepare("UPDATE files SET folder_id = ? WHERE id = ?");
$stmt->execute([$folderId, $fileId]);

// Логирование перемещения файла
logAudit($pdo, $currentUser['id'], 'move', $fileId, $folderId, [
    'file_name' => $fileName,
    'from_folder' => $fromFolderName ?? 'root',
    'to_folder' => $toFolderName ?? 'root'
]);

echo json_encode(['status' => 'success', 'message' => 'File moved']);