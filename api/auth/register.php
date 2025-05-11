<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

require_once '../../db_connection.php';

error_log('Registration request received'); // Debug log

// Check request method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

// Get and validate input data
$data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

error_log('Received data: ' . print_r($data, true)); // Debug log

if (empty($data['username']) || empty($data['email']) || empty($data['password']) || empty($data['full_name'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit();
}

try {
    // Check if username exists
    $stmt = $mysqli->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->bind_param("s", $data['username']);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Username already exists']);
        exit();
    }

    // Check if email exists
    $stmt = $mysqli->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->bind_param("s", $data['email']);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Email already exists']);
        exit();
    }

    // Hash password
    $password_hash = password_hash($data['password'], PASSWORD_DEFAULT);

    // Insert new user
    $stmt = $mysqli->prepare("INSERT INTO users (username, email, password_hash, full_name) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $data['username'], $data['email'], $password_hash, $data['full_name']);
    
    if ($stmt->execute()) {
        $user_id = $mysqli->insert_id;
        error_log("User registered successfully with ID: $user_id"); // Debug log
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Registration successful',
            'user_id' => $user_id
        ]);
    } else {
        throw new Exception("Database error: " . $mysqli->error);
    }
} catch (Exception $e) {
    error_log("Registration error: " . $e->getMessage()); // Debug log
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Registration failed: ' . $e->getMessage()
    ]);
}

$mysqli->close();
?>