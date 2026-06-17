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

if (!isset($_GET['id'])) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'File ID required']));
}

$fileId = (int)$_GET['id'];

// Получаем информацию о файле
$stmt = $pdo->prepare("
    SELECT f.*, u.nickname
    FROM files f
    JOIN users u ON f.user_id = u.id
    WHERE f.id = ?
");
$stmt->execute([$fileId]);
$file = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$file) {
    http_response_code(404);
    die(json_encode(['status' => 'error', 'message' => 'File not found in database']));
}

// Проверяем доступ (общий файл или свой)
if ($file['is_public'] == 0 && $file['user_id'] != $currentUser['id']) {
    http_response_code(403);
    die(json_encode(['status' => 'error', 'message' => 'Access denied']));
}

$filePath = __DIR__ . '/files/' . $file['stored_name'];

if (!file_exists($filePath)) {
    http_response_code(404);
    die(json_encode(['status' => 'error', 'message' => 'Physical file not found at: ' . $filePath]));
}

// Логирование скачивания (только для полных скачиваний, не для миниатюр)
$wantThumbnail = isset($_GET['thumbnail']) && $_GET['thumbnail'] === '1';
if (!$wantThumbnail) {
    logAudit($pdo, $currentUser['id'], 'download', $fileId, $file['folder_id'], [
        'file_name' => $file['original_name']
    ]);
}

// ----- МИНИАТЮРЫ (v4.2) -----
if ($wantThumbnail) {
    $ext = strtolower(pathinfo($file['original_name'], PATHINFO_EXTENSION));
    $imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!in_array($ext, $imageExts)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Thumbnail not available for this file type']);
        exit;
    }
    // Создаём уменьшенную копию
    $srcImage = null;
    switch ($ext) {
        case 'jpg':
        case 'jpeg': $srcImage = @imagecreatefromjpeg($filePath); break;
        case 'png':  $srcImage = @imagecreatefrompng($filePath);  break;
        case 'gif':  $srcImage = @imagecreatefromgif($filePath);  break;
        case 'webp': $srcImage = @imagecreatefromwebp($filePath); break;
        default: $srcImage = null;
    }
    if (!$srcImage) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Failed to process image']);
        exit;
    }
    $origW = imagesx($srcImage);
    $origH = imagesy($srcImage);
    $maxSide = 200;
    if ($origW > $origH) {
        $newW = $maxSide;
        $newH = (int)($origH * ($maxSide / $origW));
    } else {
        $newH = $maxSide;
        $newW = (int)($origW * ($maxSide / $origH));
    }
    $thumb = imagecreatetruecolor($newW, $newH);
    imagecopyresampled($thumb, $srcImage, 0, 0, 0, 0, $newW, $newH, $origW, $origH);
    imagedestroy($srcImage);

    header('Content-Type: image/jpeg');
    imagejpeg($thumb, null, 80);
    imagedestroy($thumb);
    exit;
}
// ----- КОНЕЦ БЛОКА МИНИАТЮР -----

// Отдаём файл
header('Content-Type: application/octet-stream');
header('Content-Disposition: attachment; filename="' . $file['original_name'] . '"');
header('Content-Length: ' . $file['file_size']);
readfile($filePath);