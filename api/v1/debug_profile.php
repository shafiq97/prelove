<?php
require_once 'config.php';
require_once 'headers.php';

error_log("PROFILE UPDATE DEBUG SCRIPT INVOKED");

// Get all headers
$headers = getallheaders();
error_log("All headers: " . json_encode($headers));

// Parse authentication header
$authHeader = null;
if (isset($headers['Authorization'])) {
    $authHeader = $headers['Authorization'];
} elseif (isset($headers['authorization'])) {
    $authHeader = $headers['authorization'];
} else {
    // Try to find auth header in any case
    foreach ($headers as $key => $value) {
        if (strtolower($key) === 'authorization') {
            $authHeader = $value;
            break;
        }
    }
}

error_log("Auth header found: " . ($authHeader ?? 'NONE'));

if ($authHeader) {
    // Extract token
    if (strpos($authHeader, 'Bearer ') === 0) {
        $token = substr($authHeader, 7);
        error_log("Token extracted: " . $token);
        
        // Try to decode the token
        try {
            // Base64 decode
            $decoded = base64_decode($token);
            error_log("Base64 decoded: " . $decoded);
            
            // JSON decode
            $userData = json_decode($decoded, true);
            if ($userData) {
                error_log("JSON decoded: " . json_encode($userData));
                echo json_encode(['success' => true, 'token_data' => $userData]);
            } else {
                error_log("JSON decode failed: " . json_last_error_msg());
                echo json_encode(['success' => false, 'error' => 'JSON decode failed: ' . json_last_error_msg()]);
            }
        } catch (Exception $e) {
            error_log("Token decode error: " . $e->getMessage());
            echo json_encode(['success' => false, 'error' => 'Token decode error: ' . $e->getMessage()]);
        }
    } else {
        error_log("Invalid token format - doesn't start with 'Bearer '");
        echo json_encode(['success' => false, 'error' => 'Invalid token format']);
    }
} else {
    error_log("No Authorization header found");
    echo json_encode(['success' => false, 'error' => 'No Authorization header found']);
}

// Log all server variables
error_log("SERVER variables: " . json_encode($_SERVER));

// Log details about user validation
$stmt = $conn->prepare("SELECT id, username, role FROM users LIMIT 5");
$stmt->execute();
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
error_log("Sample users in database: " . json_encode($users));
?>
