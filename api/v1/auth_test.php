<?php
// Additional debug script for auth test
require_once 'config.php';
require_once 'headers.php';

error_log("Auth Test Debug Script Started");

// Get all request details
$method = $_SERVER['REQUEST_METHOD'];
$uri = $_SERVER['REQUEST_URI'];
$headers = getallheaders();
$body = file_get_contents('php://input');

error_log("Request Method: $method");
error_log("Request URI: $uri");
error_log("Request Headers: " . json_encode($headers));
error_log("Request Body: $body");

// Get auth header specifically
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? null;
error_log("Auth Header: " . ($auth_header ?? 'Not Found'));

// Verify token if present
if ($auth_header && strpos($auth_header, 'Bearer ') === 0) {
    $token = substr($auth_header, 7);
    error_log("Extracted Token: $token");
    
    $user_data = verifyToken($token);
    if ($user_data) {
        error_log("Token Verification Success: " . json_encode($user_data));
        echo json_encode([
            'success' => true,
            'message' => 'Authentication successful',
            'user' => $user_data
        ]);
    } else {
        error_log("Token Verification Failed");
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid token'
        ]);
    }
} else {
    error_log("No valid Authorization header found");
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'Missing or invalid Authorization header'
    ]);
}
?>
