<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['status' => 'error', 'message' => 'Method not allowed']));
}

// Подключаем проверку токена
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

// Проверяем токен и получаем текущего пользователя
$currentUser = authenticate($pdo);

// Проверяем, передан ли файл
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    $error = $_FILES['file']['error'] ?? 'No file sent';
    die(json_encode(['status' => 'error', 'message' => 'File upload failed: ' . $error]));
}

$file = $_FILES['file'];
$maxSize = 300 * 1024 * 1024; // 300 MB

if ($file['size'] > $maxSize) {
    http_response_code(413);
    die(json_encode(['status' => 'error', 'message' => 'File too large. Max 300 MB']));
}

// Определяем параметры ДО их использования
$isPublic = isset($_POST['is_public']) && $_POST['is_public'] == '1';
$folderId = isset($_POST['folder_id']) && $_POST['folder_id'] !== '' ? (int)$_POST['folder_id'] : null;
$description = null;
if (isset($_POST['description']) && $_POST['description'] !== '') {
    $description = mb_substr($_POST['description'], 0, 300);
}

// Проверяем папку, если указана
if ($folderId !== null) {
    $stmt = $pdo->prepare("SELECT user_id FROM folders WHERE id = ?");
    $stmt->execute([$folderId]);
    $folder = $stmt->fetch();
    if (!$folder) {
        http_response_code(404);
        die(json_encode(['status' => 'error', 'message' => 'Target folder not found']));
    }
    if ($folder['user_id'] != $currentUser['id'] && $currentUser['is_admin'] != 1) {
        http_response_code(403);
        die(json_encode(['status' => 'error', 'message' => 'Access denied to folder']));
    }
}

// Разрешаем любые типы файлов
$originalName = basename($file['name']);
$extension = pathinfo($originalName, PATHINFO_EXTENSION);
$storedName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;

// Папка для файлов
$uploadDir = __DIR__ . '/files/';
$destination = $uploadDir . $storedName;

// Создаём папку, если нет
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

if (!move_uploaded_file($file['tmp_name'], $destination)) {
    http_response_code(500);
    die(json_encode(['status' => 'error', 'message' => 'Failed to save file']));
}

// Сохраняем в БД — ТОЛЬКО ОДИН РАЗ
$stmt = $pdo->prepare("
    INSERT INTO files (user_id, original_name, stored_name, file_size, file_type, is_public, folder_id, description)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
");
$stmt->execute([
    $currentUser['id'],
    $originalName,
    $storedName,
    $file['size'],
    $extension,
    $isPublic ? 1 : 0,
    $folderId,
    $description
]);

$fileId = $pdo->lastInsertId();

// Логирование загрузки файла
logAudit($pdo, $currentUser['id'], 'upload', $fileId, $folderId, [
    'file_name' => $originalName,
    'file_size' => $file['size']
]);

// Отправляем уведомление администраторам о новом файле
require_once __DIR__ . '/notification_helper.php';
$uploaderName = $currentUser['nickname'] ?? $currentUser['phone'] ?? 'Пользователь';
notifyAdmins($pdo,
    '📎 Новый файл',
    "{$uploaderName} загрузил(а): {$originalName}",
    [
        'file_id' => $fileId,
        'folder_id' => $folderId,
        'action' => 'file_uploaded'
    ]
);

echo json_encode([
    'status' => 'success',
    'message' => 'File uploaded',
    'file_id' => $fileId,
    'stored_name' => $storedName
]);