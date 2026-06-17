<?php
// log_action.php  хелпер для записи действий в audit_log

function logAudit($pdo, $userId, $action, $fileId = null, $folderId = null, $details = null) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? null;
    $detailsJson = $details ? json_encode($details, JSON_UNESCAPED_UNICODE) : null;
    
    $stmt = $pdo->prepare("INSERT INTO audit_log (user_id, action, file_id, folder_id, details, ip_address) 
                           VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$userId, $action, $fileId, $folderId, $detailsJson, $ip]);
}
