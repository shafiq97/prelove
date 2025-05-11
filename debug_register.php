<?php
// Enable PHP error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers, Content-Type, Access-Control-Allow-Methods, Authorization, X-Requested-With');

// Instead of writing to a log file with potential permission issues,
// we'll include debug info in the response
$debug_info = [
    'time' => date('Y-m-d H:i:s'),
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'post_data' => $_POST,
];

// Check if it's a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'success' => false,
        'error' => 'Only POST method is allowed',
        'debug' => $debug_info
    ]);
    exit();
}

// Sanitize POST data for debug output (hide password)
$safe_post = $_POST;
if (isset($safe_post['password'])) {
    $safe_post['password'] = '***HIDDEN***';
}
$debug_info['post_data'] = $safe_post;

// Database connection
$host = 'localhost';
$user = 'root';
$password = '';
$database = 'prelove_db';

// Create database connection
try {
    $mysqli = new mysqli($host, $user, $password, $database);
    $debug_info['db_connection_attempt'] = true;
    
    if ($mysqli->connect_error) {
        $error = "Connection failed: " . $mysqli->connect_error;
        $debug_info['db_error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    
    $debug_info['db_connected'] = true;
} catch (Exception $e) {
    $error = "Connection exception: " . $e->getMessage();
    $debug_info['db_exception'] = $error;
    echo json_encode([
        'success' => false,
        'error' => $error,
        'debug' => $debug_info
    ]);
    exit();
}

// Extract form data
$username = isset($_POST['username']) ? $_POST['username'] : null;
$email = isset($_POST['email']) ? $_POST['email'] : null;
$password = isset($_POST['password']) ? $_POST['password'] : null;
$fullName = isset($_POST['full_name']) ? $_POST['full_name'] : null;

// Validate inputs
if (!$username || !$email || !$password || !$fullName) {
    $missing_fields = [];
    if (!$username) $missing_fields[] = 'username';
    if (!$email) $missing_fields[] = 'email';
    if (!$password) $missing_fields[] = 'password';
    if (!$fullName) $missing_fields[] = 'full_name';
    
    $error = 'Missing required fields: ' . implode(', ', $missing_fields);
    $debug_info['validation_error'] = $error;
    $debug_info['fields'] = [
        'username_present' => !empty($username),
        'email_present' => !empty($email),
        'password_present' => !empty($password),
        'full_name_present' => !empty($fullName)
    ];
    
    echo json_encode([
        'success' => false,
        'error' => $error,
        'debug' => $debug_info
    ]);
    exit();
}

// Hash the password
$password_hash = password_hash($password, PASSWORD_DEFAULT);
$debug_info['password_hashed'] = true;

// Try to insert into the database
try {
    // Check if username exists
    $stmt = $mysqli->prepare("SELECT id FROM users WHERE username = ?");
    if (!$stmt) {
        $error = "Prepare failed: " . $mysqli->error;
        $debug_info['error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $error = "Username already exists";
        $debug_info['error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    $stmt->close();
    
    // Check if email exists
    $stmt = $mysqli->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $error = "Email already exists";
        $debug_info['error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    $stmt->close();
    
    $debug_info['user_checks_passed'] = true;
    
    // Insert user into database
    $stmt = $mysqli->prepare("INSERT INTO users (username, email, password_hash, full_name) VALUES (?, ?, ?, ?)");
    if (!$stmt) {
        $error = "Prepare failed: " . $mysqli->error;
        $debug_info['error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    
    $stmt->bind_param("ssss", $username, $email, $password_hash, $fullName);
    $debug_info['attempting_insert'] = true;
    
    if ($stmt->execute()) {
        $new_user_id = $mysqli->insert_id;
        $debug_info['success'] = true;
        $debug_info['user_id'] = $new_user_id;
        
        echo json_encode([
            'success' => true, 
            'message' => 'Registration successful',
            'user_id' => $new_user_id,
            'debug' => $debug_info
        ]);
        http_response_code(201);
    } else {
        $error = "Execute failed: " . $stmt->error;
        $debug_info['error'] = $error;
        echo json_encode([
            'success' => false,
            'error' => $error,
            'debug' => $debug_info
        ]);
        exit();
    }
    $stmt->close();
    
} catch (Exception $e) {
    $error = "Exception: " . $e->getMessage();
    $debug_info['exception'] = $error;
    echo json_encode([
        'success' => false,
        'error' => $error,
        'debug' => $debug_info
    ]);
}

// Close connection
$mysqli->close();
?>