<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/auth.php';

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

// Проверка прав администратора
if (!$currentUser['is_admin']) {
    http_response_code(403);
    echo json_encode(['error' => 'Доступ запрещён. Требуются права администратора.']);
    exit();
}

// Получаем параметры фильтрации
$userId = $_GET['user_id'] ?? null;
$action = $_GET['action'] ?? null;
$dateFrom = $_GET['date_from'] ?? null;
$dateTo = $_GET['date_to'] ?? null;
$limit = min((int)($_GET['limit'] ?? 50), 100);
$offset = (int)($_GET['offset'] ?? 0);

// Построение запроса
$where = [];
$params = [];

if ($userId) {
    $where[] = 'a.user_id = ?';
    $params[] = (int)$userId;
}

if ($action) {
    $where[] = 'a.action = ?';
    $params[] = $action;
}

if ($dateFrom) {
    $where[] = 'a.created_at >= ?';
    $params[] = $dateFrom . ' 00:00:00';
}

if ($dateTo) {
    $where[] = 'a.created_at <= ?';
    $params[] = $dateTo . ' 23:59:59';
}

$whereClause = '';
if (!empty($where)) {
    $whereClause = 'WHERE ' . implode(' AND ', $where);
}

// Запрос с JOIN для получения nickname пользователя
$sql = "SELECT a.*, u.nickname 
        FROM audit_log a 
        JOIN users u ON a.user_id = u.id 
        $whereClause 
        ORDER BY a.created_at DESC 
        LIMIT $limit OFFSET $offset";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Получаем общее количество записей для пагинации
$countSql = "SELECT COUNT(*) as total FROM audit_log a $whereClause";
$countStmt = $pdo->prepare($countSql);
$countStmt->execute($params);
$total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];

// Декодируем JSON-поле details
foreach ($logs as &$log) {
    if (!empty($log['details'])) {
        $log['details'] = json_decode($log['details'], true);
    }
    $log['id'] = (int)$log['id'];
    $log['user_id'] = (int)$log['user_id'];
    $log['file_id'] = $log['file_id'] ? (int)$log['file_id'] : null;
    $log['folder_id'] = $log['folder_id'] ? (int)$log['folder_id'] : null;
}

echo json_encode([
    'success' => true,
    'data' => $logs,
    'total' => (int)$total,
    'limit' => $limit,
    'offset' => $offset
]);