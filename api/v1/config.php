<?php
// Database connection parameters
$host = 'localhost';
$dbname = 'prelove_db';
$username = 'root';
$password = '';

// Connect to database
try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    error_log("Database connection successful");
} catch (PDOException $e) {
    error_log("Database connection error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed', 'details' => $e->getMessage()]);
    exit;
}

// Function to generate JWT token for authentication
function generateToken($user_id, $username, $role) {
    $issuedAt = time();
    $expirationTime = $issuedAt + (86400 * 365); // Token valid for 1 year
    
    $payload = [
        'user_id' => $user_id,
        'username' => $username,
        'role' => $role,
        'iat' => $issuedAt,
        'exp' => $expirationTime
    ];
    
    error_log("Generating token with payload: " . json_encode($payload));
    $token = base64_encode(json_encode($payload));
    error_log("Generated token: " . $token);
    return $token;
}

// Function to verify JWT token - SIMPLIFIED VERSION
function verifyToken($token) {
    try {
        error_log("Starting token verification");
        error_log("Token received: " . substr($token, 0, 20) . "...");
        
        // TEST MODE - FOR DEVELOPMENT ONLY
        // Always return a valid test user regardless of token
        // REMOVE THIS IN PRODUCTION!
        // Comment out the following block to enable real token verification
        /*
        return [
            'user_id' => 1,
            'username' => 'test_user',
            'role' => 'user'
        ];
        */
        
        // Check for empty token
        if (empty($token)) {
            error_log("Empty token provided");
            return false;
        }
        
        // Normal validation logic below (for production use)
        // Step 1: Base64 decode
        $base64_decoded = base64_decode($token);
        if ($base64_decoded === false) {
            error_log("Base64 decoding failed");
            return false;
        }
        error_log("Base64 decoded successfully: " . $base64_decoded);
        
        // Step 2: JSON decode
        $decoded = json_decode($base64_decoded, true);
        if ($decoded === null) {
            error_log("JSON decode failed. Error: " . json_last_error_msg());
            return false;
        }
        error_log("JSON decoded successfully: " . json_encode($decoded));
        
        error_log("Decoded token: " . json_encode($decoded));
        
        // ONLY check that we have a user_id and username
        if (!isset($decoded['user_id']) || !isset($decoded['username'])) {
            error_log("Token missing required user_id or username");
            return false;
        }
        
        // COMPLETELY IGNORE expiration time for now
        
        // Quick check if user exists (optional but good for security)
        global $conn;
        $stmt = $conn->prepare("SELECT id FROM users WHERE id = :user_id");
        $stmt->bindParam(':user_id', $decoded['user_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        if ($stmt->rowCount() === 0) {
            error_log("User ID not found in database: " . $decoded['user_id']);
            return false;
        }
        
        error_log("Token verified successfully for user ID: " . $decoded['user_id']);
        return $decoded;
        
    } catch (Exception $e) {
        error_log("Token verification error: " . $e->getMessage());
        return false;
    }
}

// Function to create error log
function logError($message, $context = []) {
    $timestamp = date('Y-m-d H:i:s');
    $contextStr = !empty($context) ? json_encode($context) : '';
    error_log("[$timestamp] $message $contextStr");
}
?>