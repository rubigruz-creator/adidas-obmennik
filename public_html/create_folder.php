<?php
header('Content-Type: application/json');

require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/log_action.php';

$host = 'localhost';
$db   = 'avito_shop';
$user = 'api_user';
$pass = 'StrongPass123!';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$pdo = new PDO($dsn, $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$currentUser = authenticate($pdo);

$input = json_decode(file_get_contents('php://input'), true);
$name = trim($input['name'] ?? '');
$parentId = isset($input['parent_id']) ? (int)$input['parent_id'] : null;

if (empty($name)) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'Folder name required']));
}

// Проверяем, существует ли родительская папка и принадлежит ли она пользователю (или админ)
if ($parentId !== null) {
    $stmt = $pdo->prepare("SELECT user_id FROM folders WHERE id = ?");
    $stmt->execute([$parentId]);
    $parent = $stmt->fetch();
    if (!$parent) {
        http_response_code(404);
        die(json_encode(['status' => 'error', 'message' => 'Parent folder not found']));
    }
    if ($parent['user_id'] != $currentUser['id'] && $currentUser['is_admin'] != 1) {
        http_response_code(403);
        die(json_encode(['status' => 'error', 'message' => 'Access denied to parent folder']));
    }
}

// Создаём папку
$stmt = $pdo->prepare("INSERT INTO folders (user_id, name, parent_id) VALUES (?, ?, ?)");
$stmt->execute([$currentUser['id'], $name, $parentId]);
$folderId = $pdo->lastInsertId();

// Логирование создания папки
logAudit($pdo, $currentUser['id'], 'create_folder', null, $folderId, [
    'folder_name' => $name
]);

echo json_encode(['status' => 'success', 'folder_id' => $folderId]);