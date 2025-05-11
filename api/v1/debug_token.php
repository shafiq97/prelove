<?php
// Token debugging script
require_once 'config.php';
require_once 'headers.php';

error_log("Token Debug Script Started");

// Details about the current request for debugging
error_log("REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD']);
error_log("REQUEST_URI: " . $_SERVER['REQUEST_URI']);
error_log("HTTP_HOST: " . ($_SERVER['HTTP_HOST'] ?? 'not set'));
error_log("SERVER_PROTOCOL: " . ($_SERVER['SERVER_PROTOCOL'] ?? 'not set'));

// Check if this is a preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    error_log("Handling OPTIONS preflight request");
    exit;
}

// Get all headers and normalize them
$allHeaders = getallheaders();
$normalizedHeaders = array();
foreach ($allHeaders as $name => $value) {
    $normalizedHeaders[strtolower($name)] = $value;
}
error_log("All Headers: " . json_encode($allHeaders));
error_log("Normalized Headers: " . json_encode($normalizedHeaders));

// Also check $_SERVER for authorization header (sometimes Apache puts it there)
foreach ($_SERVER as $key => $value) {
    if (strpos(strtolower($key), 'authorization') !== false) {
        error_log("Found in _SERVER: $key => $value");
        if (!isset($normalizedHeaders['authorization'])) {
            $normalizedHeaders['authorization'] = $value;
        }
    }
}

// Check for Authorization header
$authHeader = null;
if (isset($normalizedHeaders['authorization'])) {
    $authHeader = $normalizedHeaders['authorization'];
} elseif (isset($allHeaders['Authorization'])) {
    $authHeader = $allHeaders['Authorization'];
}

if (!$authHeader) {
    error_log("No Authorization header found");
    echo json_encode(['success' => false, 'error' => 'No Authorization header found']);
    exit;
}

error_log("Auth header: " . $authHeader);

if (strpos($authHeader, 'Bearer ') !== 0) {
    error_log("Invalid token format");
    echo json_encode(['success' => false, 'error' => 'Invalid token format']);
    exit;
}

$token = substr($authHeader, 7);
error_log("Extracted token: " . $token);

if (trim($token) === '') {
    error_log("Empty token provided");
    echo json_encode(['success' => false, 'error' => 'Empty token provided']);
    exit;
}

// Detailed debugging of token processing
error_log("RAW TOKEN: " . $token);

// Step 1: Base64 decode
$base64_decoded = base64_decode($token);
if ($base64_decoded === false) {
    error_log("Base64 decoding failed");
    echo json_encode(['success' => false, 'error' => 'Base64 decoding failed']);
    exit;
}
error_log("Base64 decoded: " . $base64_decoded);

// Step 2: JSON decode
$decoded = json_decode($base64_decoded, true);
if ($decoded === null) {
    error_log("JSON decode failed. Error: " . json_last_error_msg());
    echo json_encode(['success' => false, 'error' => 'JSON decode failed: ' . json_last_error_msg()]);
    exit;
}
error_log("JSON decoded: " . json_encode($decoded));

// Check for required fields
if (!isset($decoded['user_id'])) {
    error_log("Missing user_id in token");
    echo json_encode(['success' => false, 'error' => 'Token missing user_id']);
    exit;
}

if (!isset($decoded['username'])) {
    error_log("Missing username in token");
    echo json_encode(['success' => false, 'error' => 'Token missing username']);
    exit;
}

// Check if user exists
global $conn;
$stmt = $conn->prepare("SELECT id FROM users WHERE id = :user_id");
$stmt->bindParam(':user_id', $decoded['user_id'], PDO::PARAM_INT);
$stmt->execute();

if ($stmt->rowCount() === 0) {
    error_log("User ID not found in database: " . $decoded['user_id']);
    echo json_encode(['success' => false, 'error' => 'User ID not found in database']);
    exit;
}

// Token passed all validation
echo json_encode([
    'success' => true,
    'message' => 'Token verified successfully',
    'token_data' => $decoded
]);
?>
