<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

// Include database connection
require_once '../config/database.php';

// Check if it's a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'error' => 'Only POST method is allowed'
    ]);
    exit();
}

// Get posted data
$data = $_POST;

// Validate input
if (empty($data['username']) || empty($data['password'])) {
    echo json_encode([
        'success' => false,
        'error' => 'Username/email and password are required'
    ]);
    exit();
}

try {
    // Check if input is username or email
    $isEmail = filter_var($data['username'], FILTER_VALIDATE_EMAIL);
    
    // Prepare query based on input type
    if ($isEmail) {
        $query = "SELECT id, username, email, password_hash, full_name, profile_image_url FROM users WHERE email = ?";
    } else {
        $query = "SELECT id, username, email, password_hash, full_name, profile_image_url FROM users WHERE username = ?";
    }
    
    // Prepare statement
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $data['username']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    // Check if user exists
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'error' => 'Invalid username/email or password'
        ]);
        exit();
    }
    
    // Fetch user data
    $user = $result->fetch_assoc();
    $stmt->close();
    
    // Verify password
    if (!password_verify($data['password'], $user['password_hash'])) {
        echo json_encode([
            'success' => false,
            'error' => 'Invalid username/email or password'
        ]);
        exit();
    }
    
    // Generate JWT token (using a simple implementation)
    $token = bin2hex(random_bytes(32)); // In production, use a proper JWT library
    
    // Return success response
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'token' => $token,
        'user' => [
            'id' => $user['id'],
            'username' => $user['username'],
            'email' => $user['email'],
            'fullName' => $user['full_name'],
            'profileImageUrl' => $user['profile_image_url']
        ]
    ]);
    
} catch(Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Login failed: ' . $e->getMessage()
    ]);
    http_response_code(500);
}

$conn->close();
?>