<?php
require_once 'api/v1/config.php';
require_once 'api/v1/headers.php';

// Get HTTP method
$method = $_SERVER['REQUEST_METHOD'];

// Get action from query parameters
$action = isset($_GET['action']) ? $_GET['action'] : null;

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

// Check if user is admin
if (!$user_data || !isset($user_data['role']) || $user_data['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Admin access required']);
    exit;
}

// Route to appropriate function based on action
if ($action) {
    switch ($action) {
        case 'get_users':
            if ($method === 'GET') {
                getUsers();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'update_user':
            if ($method === 'PUT') {
                updateUser();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'delete_user':
            if ($method === 'DELETE') {
                deleteUser();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'set_role':
            if ($method === 'PUT') {
                setUserRole();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'get_stats':
            if ($method === 'GET') {
                getAdminStats();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
    exit;
}

// Function to get all users
function getUsers() {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT id, username, email, full_name, role, created_at, updated_at
            FROM users
            ORDER BY created_at DESC
        ");
        $stmt->execute();
        
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'users' => $users
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch users: ' . $e->getMessage()]);
    }
}

// Function to update user information
function updateUser() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'User ID is required']);
        return;
    }
    
    // Build update statement
    $update_fields = [];
    $params = [
        ':id' => $data['id']
    ];
    
    // Fields that can be updated
    $allowed_fields = ['username', 'email', 'full_name', 'profile_image_url'];
    
    foreach ($allowed_fields as $field) {
        if (isset($data[$field]) && !empty($data[$field])) {
            $update_fields[] = "$field = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    if (empty($update_fields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        return;
    }
    
    $update_fields[] = "updated_at = NOW()";
    
    try {
        $sql = "UPDATE users SET " . implode(', ', $update_fields) . " WHERE id = :id";
        $stmt = $conn->prepare($sql);
        
        foreach ($params as $param => $value) {
            $stmt->bindValue($param, $value);
        }
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'User updated successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update user: ' . $e->getMessage()]);
    }
}

// Function to delete a user
function deleteUser() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'User ID is required']);
        return;
    }
    
    try {
        // Begin transaction
        $conn->beginTransaction();
        
        // Delete user's items
        $delete_items = $conn->prepare("DELETE FROM items WHERE seller_id = :user_id");
        $delete_items->bindParam(':user_id', $data['id']);
        $delete_items->execute();
        
        // Delete user's outfits
        $delete_outfits = $conn->prepare("DELETE FROM outfits WHERE user_id = :user_id");
        $delete_outfits->bindParam(':user_id', $data['id']);
        $delete_outfits->execute();
        
        // Delete user's events
        $delete_events = $conn->prepare("DELETE FROM events WHERE user_id = :user_id");
        $delete_events->bindParam(':user_id', $data['id']);
        $delete_events->execute();
        
        // Delete the user
        $delete_user = $conn->prepare("DELETE FROM users WHERE id = :id");
        $delete_user->bindParam(':id', $data['id']);
        $delete_user->execute();
        
        // Commit transaction
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'User and all associated data deleted successfully'
        ]);
    } catch (PDOException $e) {
        // Rollback on error
        $conn->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete user: ' . $e->getMessage()]);
    }
}

// Function to set a user's role (admin or regular user)
function setUserRole() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id']) || !isset($data['role'])) {
        http_response_code(400);
        echo json_encode(['error' => 'User ID and role are required']);
        return;
    }
    
    // Validate role
    $valid_roles = ['admin', 'user'];
    if (!in_array($data['role'], $valid_roles)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid role. Valid roles are: ' . implode(', ', $valid_roles)]);
        return;
    }
    
    try {
        $stmt = $conn->prepare("UPDATE users SET role = :role WHERE id = :id");
        $stmt->bindParam(':role', $data['role']);
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => "User role updated to '{$data['role']}' successfully"
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update user role: ' . $e->getMessage()]);
    }
}

// Function to get admin dashboard statistics
function getAdminStats() {
    global $conn;
    
    try {
        // Total users
        $user_stmt = $conn->prepare("SELECT COUNT(*) as count FROM users");
        $user_stmt->execute();
        $user_count = $user_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Total items
        $item_stmt = $conn->prepare("SELECT COUNT(*) as count FROM items");
        $item_stmt->execute();
        $item_count = $item_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Total outfits
        $outfit_stmt = $conn->prepare("SELECT COUNT(*) as count FROM outfits");
        $outfit_stmt->execute();
        $outfit_count = $outfit_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Total events
        $event_stmt = $conn->prepare("SELECT COUNT(*) as count FROM events");
        $event_stmt->execute();
        $event_count = $event_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // User registration trend (last 6 months)
        $user_trend_stmt = $conn->prepare("
            SELECT DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*) as count
            FROM users
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(created_at, '%Y-%m')
            ORDER BY month
        ");
        $user_trend_stmt->execute();
        $user_trend = $user_trend_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Item categories
        $category_stmt = $conn->prepare("
            SELECT category, COUNT(*) as count
            FROM items
            GROUP BY category
            ORDER BY count DESC
        ");
        $category_stmt->execute();
        $categories = $category_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'stats' => [
                'user_count' => $user_count,
                'item_count' => $item_count,
                'outfit_count' => $outfit_count,
                'event_count' => $event_count,
                'user_trend' => $user_trend,
                'categories' => $categories
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch statistics: ' . $e->getMessage()]);
    }
}
?>
