<?php
header('Content-Type: application/json');
require_once 'auth.php';
require_once 'log_action.php';

$host = 'localhost';
$db   = 'avito_shop';
$dbUser = 'api_user';
$dbPass = 'StrongPass123!';

$dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
$pdo = new PDO($dsn, $dbUser, $dbPass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$user = authenticate($pdo);
if (!$user) {
    echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);
$folderId = $data['folder_id'] ?? null;
$targetFolderId = $data['target_folder_id'] ?? null; // null = корень

if (!$folderId) {
    echo json_encode(['status' => 'error', 'message' => 'folder_id required']);
    exit;
}

// Проверка, что папка существует и пользователь имеет права
$stmt = $pdo->prepare("SELECT * FROM folders WHERE id = ?");
$stmt->execute([$folderId]);
$folder = $stmt->fetch();

if (!$folder) {
    echo json_encode(['status' => 'error', 'message' => 'Folder not found']);
    exit;
}

// Админ может перемещать любые папки, обычный пользователь — только свои
if (!$user['is_admin'] && $folder['user_id'] != $user['id']) {
    echo json_encode(['status' => 'error', 'message' => 'Access denied']);
    exit;
}

// Защита от рекурсии: нельзя переместить папку в саму себя или в своего потомка
if ($targetFolderId) {
    $checkId = $targetFolderId;
    while ($checkId) {
        if ($checkId == $folderId) {
            echo json_encode(['status' => 'error', 'message' => 'Cannot move folder into itself']);
            exit;
        }
        $stmt = $pdo->prepare("SELECT parent_id FROM folders WHERE id = ?");
        $stmt->execute([$checkId]);
        $parent = $stmt->fetch();
        $checkId = $parent ? $parent['parent_id'] : null;
    }
}

// Сохраняем данные для лога
$folderName = $folder['name'];
$fromFolderId = $folder['parent_id'];

// Получаем имена папок
$fromFolderName = null;
if ($fromFolderId) {
    $stmt = $pdo->prepare("SELECT name FROM folders WHERE id = ?");
    $stmt->execute([$fromFolderId]);
    $f = $stmt->fetch();
    $fromFolderName = $f ? $f['name'] : null;
}

$toFolderName = null;
if ($targetFolderId) {
    $stmt = $pdo->prepare("SELECT name FROM folders WHERE id = ?");
    $stmt->execute([$targetFolderId]);
    $t = $stmt->fetch();
    $toFolderName = $t ? $t['name'] : null;
}

$stmt = $pdo->prepare("UPDATE folders SET parent_id = ? WHERE id = ?");
$stmt->execute([$targetFolderId, $folderId]);

// Логирование перемещения папки
logAudit($pdo, $user['id'], 'move_folder', null, $folderId, [
    'folder_name' => $folderName,
    'from_folder' => $fromFolderName ?? 'root',
    'to_folder' => $toFolderName ?? 'root'
]);

echo json_encode(['status' => 'success']);