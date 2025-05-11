<?php
require_once 'api/v1/config.php';
require_once 'api/v1/headers.php';

// Get HTTP method
$method = $_SERVER['REQUEST_METHOD'];

// Only allow GET requests
if ($method !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// STANDARDIZED AUTHENTICATION FOR ALL API REQUESTS
$headers = getallheaders();

// Look for Authorization header in a case-insensitive way
$authHeader = null;
if (isset($headers['Authorization'])) {
    $authHeader = $headers['Authorization'];
} elseif (isset($headers['authorization'])) {
    $authHeader = $headers['authorization'];
}

if (!$authHeader) {
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

if (strpos($authHeader, 'Bearer ') !== 0) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token format']);
    exit;
}

$token = substr($authHeader, 7);
$user_data = verifyToken($token);

// Check token validity
if (!$user_data) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid or expired token']);
    exit;
}

// Return user role information
$response = [
    'success' => true,
    'user' => [
        'id' => $user_data['user_id'],
        'username' => $user_data['username'],
        'role' => $user_data['role'] ?? 'user',
        'is_admin' => isset($user_data['role']) && $user_data['role'] === 'admin'
    ]
];

echo json_encode($response);
?>
