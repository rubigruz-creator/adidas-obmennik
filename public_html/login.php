<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['status' => 'error', 'message' => 'Method not allowed']));
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input || empty($input['phone']) || empty($input['password'])) {
    http_response_code(400);
    die(json_encode(['status' => 'error', 'message' => 'Phone and password required']));
}

$host = 'localhost';
$db   = 'avito_shop';
$user = 'api_user';
$pass = 'StrongPass123!';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

require_once __DIR__ . '/log_action.php';

try {
    $pdo = new PDO($dsn, $user, $pass, $options);

    $pdo->exec("DELETE FROM user_sessions WHERE expires_at < NOW()");

    $stmt = $pdo->prepare("SELECT id, password_hash, nickname, full_name, position, is_admin FROM users WHERE phone = ?");
    $stmt->execute([$input['phone']]);
    $userData = $stmt->fetch();

    if (!$userData || !password_verify($input['password'], $userData['password_hash'])) {
        http_response_code(401);
        die(json_encode(['status' => 'error', 'message' => 'Invalid phone or password']));
    }

    $apiToken = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));

    $stmt = $pdo->prepare("DELETE FROM user_sessions WHERE user_id = ?");
    $stmt->execute([$userData['id']]);

    $stmt = $pdo->prepare("INSERT INTO user_sessions (user_id, api_token, expires_at) VALUES (?, ?, ?)");
    $stmt->execute([$userData['id'], $apiToken, $expiresAt]);

    logAudit($pdo, $userData['id'], 'login');

    unset($userData['password_hash']);

    if (!isset($userData['is_admin'])) {
        $userData['is_admin'] = 0;
    }

    echo json_encode([
        'status' => 'success',
        'api_token' => $apiToken,
        'user' => $userData,
        'expires_at' => $expiresAt
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
}