<?php
require_once 'headers.php';
require_once 'config.php';

// Get action from query parameters
$action = isset($_GET['action']) ? $_GET['action'] : null;
error_log("Auth API - Action: " . ($action ?? 'null'));

if ($action) {
    switch ($action) {
        case 'login':
            handleLogin();
            break;
        case 'register':
            handleRegister();
            break;
        case 'verify-token':
            verifyUserToken();
            break;
        case 'get_profile':
            getProfile();
            break;
        case 'update_profile':
            updateProfile();
            break;
        case 'get_settings':
            getSettings();
            break;
        case 'update_settings':
            updateSettings();
            break;
        case 'change_password':
            changePassword();
            break;
        case 'test_token':
            testToken();
            break;
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
    exit;
}

// Function to handle login
function handleLogin() {
    global $conn;
    error_log("Processing login request");
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }

    // Get JSON data from request body
    $input = file_get_contents('php://input');
    error_log("Raw input: " . $input);
    $data = json_decode($input, true);
    error_log("Decoded input: " . json_encode($data));

    if (!isset($data['username']) || !isset($data['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Username and password are required']);
        return;
    }

    try {
        $stmt = $conn->prepare("SELECT * FROM users WHERE username = :username OR email = :email");
        $stmt->bindParam(':username', $data['username']);
        $stmt->bindParam(':email', $data['username']);
        $stmt->execute();
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        error_log("User found: " . ($user ? "yes" : "no"));
        
        if ($user) {
            error_log("Username from DB: " . $user['username']);
            error_log("Password from request: " . $data['password']);
            error_log("Stored hash: " . $user['password_hash']);
            
            // Check if the password column is actually named password_hash instead of password
            $password_column = isset($user['password']) ? 'password' : 'password_hash';
            $stored_hash = $user[$password_column];
            
            error_log("Using password column: " . $password_column);
            error_log("Password verification result: " . (password_verify($data['password'], $stored_hash) ? "true" : "false"));
            
            if (password_verify($data['password'], $stored_hash)) {
                error_log("Password verified successfully");
                // Generate token with proper role
                $role = isset($user['role']) ? $user['role'] : 'user';
                error_log("User role: " . $role);
                $token = generateToken($user['id'], $user['username'], $role);
                error_log("Generated token: " . $token);
                
                // Return success response with minimal user data
                echo json_encode([
                    'success' => true,
                    'message' => 'Login successful',
                    'token' => $token,
                    'user' => [
                        'id' => $user['id'],
                        'username' => $user['username'],
                        'email' => $user['email'],
                        'full_name' => $user['full_name'],
                        'role' => $user['role'] ?? 'user'
                    ]
                ]);
            } else {
                error_log("Invalid credentials");
                http_response_code(401);
                echo json_encode(['error' => 'Invalid credentials']);
            }
        } else {
            error_log("Invalid credentials");
            http_response_code(401);
            echo json_encode(['error' => 'Invalid credentials']);
        }
    } catch (PDOException $e) {
        error_log("Login error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Login failed: ' . $e->getMessage()]);
    }
}

// Function to handle registration
function handleRegister() {
    global $conn;
    
    // Only allow POST for registration
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    // Get JSON data from request body
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    $required_fields = ['full_name', 'email', 'username', 'password', 'phone', 'address', 'terms_accepted', 'recaptcha_response'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode(['error' => "Field '$field' is required"]);
            return;
        }
    }
    
    // Verify reCAPTCHA (implementation depends on how you want to handle it in Flutter)
    $recaptcha_response = $data['recaptcha_response'];
    $recaptcha_secret = '6LdDyAErAAAAAM4tRitCAW3Mchl0YB2PrtJDCNRk'; // Use your actual secret key
    
    $recaptcha_url = 'https://www.google.com/recaptcha/api/siteverify';
    $recaptcha_data = [
        'secret' => $recaptcha_secret,
        'response' => $recaptcha_response
    ];
    
    $options = [
        'http' => [
            'header' => "Content-type: application/x-www-form-urlencoded\r\n",
            'method' => 'POST',
            'content' => http_build_query($recaptcha_data)
        ]
    ];
    
    $context = stream_context_create($options);
    $result = file_get_contents($recaptcha_url, false, $context);
    $result_json = json_decode($result, true);
    
    if (!$result_json['success']) {
        http_response_code(400);
        echo json_encode(['error' => 'reCAPTCHA verification failed']);
        return;
    }
    
    // Check if terms are accepted
    if (!$data['terms_accepted']) {
        http_response_code(400);
        echo json_encode(['error' => 'You must accept the terms and conditions']);
        return;
    }
    
    // Check if email already exists
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = :email OR username = :username");
    $stmt->bindParam(':email', $data['email']);
    $stmt->bindParam(':username', $data['username']);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $existing_user = $stmt->fetch();
        if ($existing_user['email'] === $data['email']) {
            http_response_code(409); // Conflict
            echo json_encode(['error' => 'Email already in use']);
        } else {
            http_response_code(409);
            echo json_encode(['error' => 'Username already in use']);
        }
        return;
    }
    
    // Hash password
    $hashed_password = password_hash($data['password'], PASSWORD_DEFAULT);
    
    // Default role for new users
    $role = 'user';
    
    // Insert new user
    $stmt = $conn->prepare("
        INSERT INTO users (username, email, password, full_name, phone, address, role) 
        VALUES (:username, :email, :password, :full_name, :phone, :address, :role)
    ");
    
    $stmt->bindParam(':username', $data['username']);
    $stmt->bindParam(':email', $data['email']);
    $stmt->bindParam(':password', $hashed_password);
    $stmt->bindParam(':full_name', $data['full_name']);
    $stmt->bindParam(':phone', $data['phone']);
    $stmt->bindParam(':address', $data['address']);
    $stmt->bindParam(':role', $role);
    
    try {
        $stmt->execute();
        
        // Get the newly created user ID
        $user_id = $conn->lastInsertId();
        
        // Generate JWT token
        $token = generateToken($user_id, $data['username'], $role);
        
        // Return success response
        echo json_encode([
            'success' => true,
            'message' => 'Registration successful',
            'user' => [
                'id' => $user_id,
                'username' => $data['username'],
                'email' => $data['email'],
                'role' => $role,
                'full_name' => $data['full_name']
            ],
            'token' => $token
        ]);
        
        // Optionally send welcome email (can be handled separately)
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Registration failed: ' . $e->getMessage()]);
    }
}

// Function to verify user token
function verifyUserToken() {
    error_log("Verifying user token");
    
    // Get all headers and normalize them for case-insensitive access
    $allHeaders = getallheaders();
    $normalizedHeaders = array();
    foreach ($allHeaders as $name => $value) {
        $normalizedHeaders[strtolower($name)] = $value;
    }
    error_log("All Headers: " . json_encode($allHeaders));
    error_log("Normalized Headers: " . json_encode($normalizedHeaders));
    
    // Try to find Authorization header (case-insensitive)
    $authHeader = null;
    if (isset($normalizedHeaders['authorization'])) {
        $authHeader = $normalizedHeaders['authorization'];
    } elseif (isset($allHeaders['Authorization'])) {
        $authHeader = $allHeaders['Authorization'];
    }
    
    if (!$authHeader) {
        error_log("No Authorization header found");
        http_response_code(401);
        echo json_encode(['error' => 'No authorization token provided']);
        return;
    }
    
    error_log("Auth header: " . $authHeader);
    
    if (strpos($authHeader, 'Bearer ') !== 0) {
        error_log("Invalid token format");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($authHeader, 7);
    error_log("Extracted token: " . $token);
    
    $decoded = verifyToken($token);
    error_log("Token verification result: " . json_encode($decoded));
    
    if ($decoded) {
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => $decoded['user_id'],
                'username' => $decoded['username'],
                'role' => $decoded['role']
            ]
        ]);
    } else {
        error_log("Token verification failed");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
    }
}

function getProfile() {
    global $conn;
    
    // Get data from request - either from token or using a user_id parameter
    $user_id = null;
    $headers = getallheaders();
    
    // Try to get user_id from token if Authentication header exists
    if (isset($headers['Authorization'])) {
        $auth_header = $headers['Authorization'];
        if (strpos($auth_header, 'Bearer ') === 0) {
            $token = substr($auth_header, 7);
            $user_data = verifyToken($token);
            
            if ($user_data) {
                $user_id = $user_data['user_id'];
            }
        }
    }
    
    // If no valid token, check for user_id parameter (for non-authenticated access)
    if (!$user_id && isset($_GET['user_id'])) {
        $user_id = (int)$_GET['user_id'];
    }
    
    // If still no user_id, return sample data or error
    if (!$user_id) {
        // Return a demo profile or error message
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => 0,
                'username' => 'Guest',
                'email' => 'guest@example.com',
                'full_name' => 'Guest User',
                'phone' => '',
                'address' => '',
                'profile_image' => '',
                'created_at' => date('Y-m-d H:i:s')
            ],
            'stats' => [
                'selling' => 0,
                'donated' => 0,
                'purchased' => 0
            ]
        ]);
        return;
    }
    
    try {
        // Get user profile data
        $stmt = $conn->prepare("
            SELECT u.id, u.username, u.email, u.full_name, u.phone, u.address, 
                   u.profile_image, u.created_at,
                   (SELECT COUNT(*) FROM items WHERE user_id = u.id AND status = 'active') as selling,
                   (SELECT COUNT(*) FROM donations WHERE user_id = u.id) as donated,
                   (SELECT COUNT(*) FROM orders WHERE user_id = u.id) as purchased
            FROM users u
            WHERE u.id = :user_id
        ");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'full_name' => $user['full_name'],
                'phone' => $user['phone'],
                'address' => $user['address'],
                'profile_image' => $user['profile_image'],
                'created_at' => $user['created_at']
            ],
            'stats' => [
                'selling' => (int)$user['selling'],
                'donated' => (int)$user['donated'],
                'purchased' => (int)$user['purchased']
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch profile: ' . $e->getMessage()]);
    }
}

// Function to update user profile
function updateProfile() {
    global $conn;
    
    // Add detailed logging for debugging
    error_log("UPDATE PROFILE ENDPOINT CALLED");
    
    // Get all headers and normalize them for case-insensitive access
    $allHeaders = getallheaders();
    $normalizedHeaders = array();
    foreach ($allHeaders as $name => $value) {
        $normalizedHeaders[strtolower($name)] = $value;
    }
    error_log("All Headers: " . json_encode($allHeaders));
    error_log("Normalized Headers: " . json_encode($normalizedHeaders));
    
    // Look for Authorization header in all possible locations
    $authHeader = null;
    
    // Check for regular or lowercase authorization header
    if (isset($normalizedHeaders['authorization'])) {
        $authHeader = $normalizedHeaders['authorization'];
        error_log("Found authorization in normalized headers");
    }
    
    // If not found, check $_SERVER for HTTP_AUTHORIZATION
    if (!$authHeader && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        error_log("Found Authorization in _SERVER['HTTP_AUTHORIZATION']");
    }
    
    // If still not found, check for other variants in $_SERVER
    if (!$authHeader) {
        foreach ($_SERVER as $key => $value) {
            if (strpos(strtolower($key), 'authorization') !== false) {
                $authHeader = $value;
                error_log("Found Authorization in _SERVER key: $key");
                break;
            }
        }
    }
    
    if (!$authHeader) {
        error_log("No Authorization header found in any location");
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required - No Authorization header found']);
        return;
    }
    
    error_log("Auth header found: " . $authHeader);
    
    // Fix for potential double "Bearer Bearer" prefix (could happen in some environments)
    if (strpos($authHeader, 'Bearer Bearer ') === 0) {
        $authHeader = 'Bearer ' . substr($authHeader, 14);
        error_log("Fixed double Bearer prefix: " . $authHeader);
    }
    
    if (strpos($authHeader, 'Bearer ') !== 0) {
        error_log("Invalid token format: " . $authHeader);
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($authHeader, 7);
    error_log("Extracted token: " . $token);
    
    if (empty(trim($token))) {
        error_log("Empty token provided");
        http_response_code(401);
        echo json_encode(['error' => 'Empty token provided']);
        return;
    }
    
    $user_data = verifyToken($token);
    error_log("Verify token result: " . ($user_data ? json_encode($user_data) : 'false'));
    
    if (!$user_data) {
        error_log("Token verification failed");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return;
    }
    
    // Handle file upload if profile image is included
    $profile_image_path = null;
    if (isset($_FILES['profile_image'])) {
        $target_dir = "../uploads/profile_images/";
        if (!file_exists($target_dir)) {
            mkdir($target_dir, 0777, true);
        }
        
        $file_extension = strtolower(pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION));
        $file_name = uniqid('profile_', true) . '.' . $file_extension;
        $target_file = $target_dir . $file_name;
        
        if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $target_file)) {
            $profile_image_path = 'uploads/profile_images/' . $file_name;
        }
    }
    
    try {
        $update_fields = [];
        $params = [':user_id' => $user_data['user_id']];
        
        // Get data from POST or JSON request body
        $data = $_POST;
        if (empty($data)) {
            $data = json_decode(file_get_contents('php://input'), true);
        }
        
        // Build update statement dynamically
        if (!empty($data['full_name'])) {
            $update_fields[] = 'full_name = :full_name';
            $params[':full_name'] = $data['full_name'];
        }
        
        if (!empty($data['email'])) {
            $update_fields[] = 'email = :email';
            $params[':email'] = $data['email'];
        }
        
        if (!empty($data['phone'])) {
            $update_fields[] = 'phone = :phone';
            $params[':phone'] = $data['phone'];
        }
        
        if (!empty($data['address'])) {
            $update_fields[] = 'address = :address';
            $params[':address'] = $data['address'];
        }
        
        if ($profile_image_path) {
            $update_fields[] = 'profile_image = :profile_image';
            $params[':profile_image'] = $profile_image_path;
        }
        
        if (empty($update_fields)) {
            http_response_code(400);
            echo json_encode(['error' => 'No fields to update']);
            return;
        }
        
        $sql = "UPDATE users SET " . implode(', ', $update_fields) . " WHERE id = :user_id";
        $stmt = $conn->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->execute();
        
        // Get updated user data
        $stmt = $conn->prepare("
            SELECT id, username, email, full_name, phone, address, profile_image, created_at
            FROM users WHERE id = :user_id
        ");
        $stmt->bindParam(':user_id', $user_data['user_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update profile: ' . $e->getMessage()]);
    }
}

function getSettings() {
    global $conn;
    
    // Check authorization
    $headers = getallheaders();
    if (!isset($headers['Authorization'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        return;
    }
    
    $auth_header = $headers['Authorization'];
    if (strpos($auth_header, 'Bearer ') !== 0) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($auth_header, 7);
    $user_data = verifyToken($token);
    
    if (!$user_data) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return;
    }
    
    try {
        // Get user settings
        $stmt = $conn->prepare("
            SELECT dark_mode, notifications, language, privacy, show_sold_items,
                   show_donated_items, outfit_suggestions, sale_notifications,
                   donation_reminders
            FROM user_settings 
            WHERE user_id = :user_id
        ");
        $stmt->bindParam(':user_id', $user_data['user_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        $settings = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$settings) {
            // If no settings exist, return defaults
            $settings = [
                'dark_mode' => false,
                'notifications' => true,
                'language' => 'en',
                'privacy' => false,
                'show_sold_items' => true,
                'show_donated_items' => true,
                'outfit_suggestions' => true,
                'sale_notifications' => true,
                'donation_reminders' => true
            ];
            
            // Insert default settings
            $stmt = $conn->prepare("
                INSERT INTO user_settings (
                    user_id, dark_mode, notifications, language, privacy,
                    show_sold_items, show_donated_items, outfit_suggestions,
                    sale_notifications, donation_reminders
                ) VALUES (
                    :user_id, :dark_mode, :notifications, :language, :privacy,
                    :show_sold_items, :show_donated_items, :outfit_suggestions,
                    :sale_notifications, :donation_reminders
                )
            ");
            
            $stmt->bindParam(':user_id', $user_data['user_id'], PDO::PARAM_INT);
            $stmt->bindParam(':dark_mode', $settings['dark_mode'], PDO::PARAM_BOOL);
            $stmt->bindParam(':notifications', $settings['notifications'], PDO::PARAM_BOOL);
            $stmt->bindParam(':language', $settings['language'], PDO::PARAM_STR);
            $stmt->bindParam(':privacy', $settings['privacy'], PDO::PARAM_BOOL);
            $stmt->bindParam(':show_sold_items', $settings['show_sold_items'], PDO::PARAM_BOOL);
            $stmt->bindParam(':show_donated_items', $settings['show_donated_items'], PDO::PARAM_BOOL);
            $stmt->bindParam(':outfit_suggestions', $settings['outfit_suggestions'], PDO::PARAM_BOOL);
            $stmt->bindParam(':sale_notifications', $settings['sale_notifications'], PDO::PARAM_BOOL);
            $stmt->bindParam(':donation_reminders', $settings['donation_reminders'], PDO::PARAM_BOOL);
            
            $stmt->execute();
        }
        
        echo json_encode([
            'success' => true,
            'settings' => $settings
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch settings: ' . $e->getMessage()]);
    }
}

function updateSettings() {
    global $conn;
    
    // Check authorization
    $headers = getallheaders();
    if (!isset($headers['Authorization'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        return;
    }
    
    $auth_header = $headers['Authorization'];
    if (strpos($auth_header, 'Bearer ') !== 0) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($auth_header, 7);
    $user_data = verifyToken($token);
    
    if (!$user_data) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return;
    }
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    try {
        // Update or insert settings
        $stmt = $conn->prepare("
            INSERT INTO user_settings (
                user_id, dark_mode, notifications, language, privacy,
                show_sold_items, show_donated_items, outfit_suggestions,
                sale_notifications, donation_reminders
            ) VALUES (
                :user_id, :dark_mode, :notifications, :language, :privacy,
                :show_sold_items, :show_donated_items, :outfit_suggestions,
                :sale_notifications, :donation_reminders
            ) ON DUPLICATE KEY UPDATE
                dark_mode = VALUES(dark_mode),
                notifications = VALUES(notifications),
                language = VALUES(language),
                privacy = VALUES(privacy),
                show_sold_items = VALUES(show_sold_items),
                show_donated_items = VALUES(show_donated_items),
                outfit_suggestions = VALUES(outfit_suggestions),
                sale_notifications = VALUES(sale_notifications),
                donation_reminders = VALUES(donation_reminders)
        ");
        
        $stmt->bindParam(':user_id', $user_data['user_id'], PDO::PARAM_INT);
        $stmt->bindParam(':dark_mode', $data['dark_mode'], PDO::PARAM_BOOL);
        $stmt->bindParam(':notifications', $data['notifications'], PDO::PARAM_BOOL);
        $stmt->bindParam(':language', $data['language'], PDO::PARAM_STR);
        $stmt->bindParam(':privacy', $data['privacy'], PDO::PARAM_BOOL);
        $stmt->bindParam(':show_sold_items', $data['show_sold_items'], PDO::PARAM_BOOL);
        $stmt->bindParam(':show_donated_items', $data['show_donated_items'], PDO::PARAM_BOOL);
        $stmt->bindParam(':outfit_suggestions', $data['outfit_suggestions'], PDO::PARAM_BOOL);
        $stmt->bindParam(':sale_notifications', $data['sale_notifications'], PDO::PARAM_BOOL);
        $stmt->bindParam(':donation_reminders', $data['donation_reminders'], PDO::PARAM_BOOL);
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Settings updated successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update settings: ' . $e->getMessage()]);
    }
}

// Helper function to authenticate a user from the Authorization header
function authenticateUser() {
    error_log("Starting authenticateUser function");
    $headers = getallheaders();
    error_log("Headers: " . json_encode($headers));
    
    if (!isset($headers['Authorization'])) {
        error_log("No Authorization header found");
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        return null;
    }
    
    $auth_header = $headers['Authorization'];
    error_log("Auth header: " . $auth_header);
    
    if (strpos($auth_header, 'Bearer ') !== 0) {
        error_log("Invalid token format");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return null;
    }
    
    $token = substr($auth_header, 7);
    error_log("Extracted token: " . $token);
    
    $user_data = verifyToken($token);
    error_log("Verify token result: " . ($user_data ? json_encode($user_data) : 'false'));
    
    if (!$user_data) {
        error_log("Token verification failed");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return null;
    }
    
    error_log("Authentication successful for user: " . $user_data['username']);
    return [
        'id' => $user_data['user_id'],
        'username' => $user_data['username'],
        'role' => $user_data['role'] ?? 'user'
    ];
}

// Function to handle changing password
function changePassword() {
    global $conn;
    error_log("Processing change password request");
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }

    // Try multiple ways to get the Authorization header
    $headers = getallheaders();
    error_log("All headers: " . json_encode($headers));
    
    // Get all headers including _SERVER variables
    $allHeaders = [];
    foreach ($_SERVER as $key => $value) {
        if (substr($key, 0, 5) === 'HTTP_') {
            $headerKey = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($key, 5)))));
            $allHeaders[$headerKey] = $value;
        }
    }
    error_log("All server headers: " . json_encode($allHeaders));
    
    // Check multiple possible locations for the Authorization header
    $authHeader = null;
    
    // Method 1: Standard getallheaders
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        error_log("Found Authorization header in getallheaders()");
    }
    // Method 2: Case-insensitive check with getallheaders
    elseif (isset($headers['authorization'])) {
        $authHeader = $headers['authorization'];
        error_log("Found authorization (lowercase) in getallheaders()");
    }
    // Method 3: Check HTTP_AUTHORIZATION in $_SERVER
    elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        error_log("Found Authorization in _SERVER['HTTP_AUTHORIZATION']");
    }
    // Method 4: Check REDIRECT_HTTP_AUTHORIZATION in $_SERVER (used by some Apache configs)
    elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        error_log("Found Authorization in _SERVER['REDIRECT_HTTP_AUTHORIZATION']");
    }
    // Method 5: Check Authorization in $_SERVER (rare)
    elseif (isset($_SERVER['Authorization'])) {
        $authHeader = $_SERVER['Authorization'];
        error_log("Found Authorization in _SERVER directly");
    }
    
    if (!$authHeader) {
        error_log("No Authorization header found in any location");
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required. No Authorization header found in any location']);
        return;
    }
    
    error_log("Auth header found: " . $authHeader);
    
    if (strpos($authHeader, 'Bearer ') !== 0) {
        error_log("Invalid token format");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($authHeader, 7);
    error_log("Extracted token: " . $token);
    
    $user_data = verifyToken($token);
    error_log("Verify token result: " . ($user_data ? json_encode($user_data) : 'false'));
    
    if (!$user_data) {
        error_log("Token verification failed");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return;
    }
    
    $user = [
        'id' => $user_data['user_id'],
        'username' => $user_data['username'],
        'role' => $user_data['role'] ?? 'user'
    ];

    // Get JSON data from request body
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (!isset($data['current_password']) || !isset($data['new_password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Current and new passwords are required']);
        return;
    }

    // Validate new password
    if (strlen($data['new_password']) < 8) {
        http_response_code(400);
        echo json_encode(['error' => 'New password must be at least 8 characters']);
        return;
    }

    try {
        // Get current user's password hash
        $stmt = $conn->prepare("SELECT password_hash FROM users WHERE id = :userId");
        $stmt->bindParam(':userId', $user['id']);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$result) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            return;
        }
        
        // Verify current password
        if (!password_verify($data['current_password'], $result['password_hash'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Current password is incorrect']);
            return;
        }
        
        // Update password
        $newPasswordHash = password_hash($data['new_password'], PASSWORD_DEFAULT);
        $stmt = $conn->prepare("UPDATE users SET password_hash = :passwordHash WHERE id = :userId");
        $stmt->bindParam(':passwordHash', $newPasswordHash);
        $stmt->bindParam(':userId', $user['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Password changed successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to change password: ' . $e->getMessage()]);
    }
}

// Function for testing token verification
function testToken() {
    error_log("Testing token verification");
    
    // Try multiple ways to get the Authorization header
    $headers = getallheaders();
    error_log("All headers: " . json_encode($headers));
    
    // Get all headers including _SERVER variables
    $allHeaders = [];
    foreach ($_SERVER as $key => $value) {
        if (substr($key, 0, 5) === 'HTTP_') {
            $headerKey = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($key, 5)))));
            $allHeaders[$headerKey] = $value;
        }
    }
    error_log("All server headers: " . json_encode($allHeaders));
    
    // Check multiple possible locations for the Authorization header
    $authHeader = null;
    
    // Method 1: Standard getallheaders
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        error_log("Found Authorization header in getallheaders()");
    }
    // Method 2: Case-insensitive check with getallheaders
    elseif (isset($headers['authorization'])) {
        $authHeader = $headers['authorization'];
        error_log("Found authorization (lowercase) in getallheaders()");
    }
    // Method 3: Check HTTP_AUTHORIZATION in $_SERVER
    elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        error_log("Found Authorization in _SERVER['HTTP_AUTHORIZATION']");
    }
    // Method 4: Check REDIRECT_HTTP_AUTHORIZATION in $_SERVER (used by some Apache configs)
    elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        error_log("Found Authorization in _SERVER['REDIRECT_HTTP_AUTHORIZATION']");
    }
    // Method 5: Check Authorization in $_SERVER (rare)
    elseif (isset($_SERVER['Authorization'])) {
        $authHeader = $_SERVER['Authorization'];
        error_log("Found Authorization in _SERVER directly");
    }
    
    if (!$authHeader) {
        error_log("No Authorization header found in any location");
        echo json_encode(['success' => false, 'error' => 'No Authorization header found in any location']);
        return;
    }
    
    error_log("Auth header found: " . $authHeader);
    
    if (strpos($authHeader, 'Bearer ') !== 0) {
        error_log("Invalid token format");
        echo json_encode(['success' => false, 'error' => 'Invalid token format']);
        return;
    }
    
    $token = substr($authHeader, 7);
    error_log("Extracted token: " . $token);
    
    $user_data = verifyToken($token);
    error_log("Verify token result: " . ($user_data ? json_encode($user_data) : 'false'));
    
    if (!$user_data) {
        error_log("Token verification failed");
        echo json_encode(['success' => false, 'error' => 'Token verification failed']);
        return;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Token verified successfully',
        'user' => [
            'id' => $user_data['user_id'],
            'username' => $user_data['username'],
            'role' => $user_data['role'] ?? 'user'
        ]
    ]);
}
?>