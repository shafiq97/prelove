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
        // Admin User Management
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
        
        // Admin Item Management
        case 'get_items':
            if ($method === 'GET') {
                getItems();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'add_item':
            if ($method === 'POST') {
                addItem();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'update_item':
            if ($method === 'PUT') {
                updateItem();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'delete_item':
            if ($method === 'DELETE') {
                deleteItem();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        
        // Admin Event Management
        case 'get_events':
            if ($method === 'GET') {
                getEvents();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'add_event':
            if ($method === 'POST') {
                addEvent();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'update_event':
            if ($method === 'PUT') {
                updateEvent();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'delete_event':
            if ($method === 'DELETE') {
                deleteEvent();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        
        // Admin Statistics
        case 'get_stats':
            if ($method === 'GET') {
                getStatistics();
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

// Function to update user
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
    $allowed_fields = ['username', 'email', 'full_name', 'role'];
    
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

// Function to delete user
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
        $stmt = $conn->prepare("DELETE FROM users WHERE id = :id");
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'User deleted successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete user: ' . $e->getMessage()]);
    }
}

// Function to get all items
function getItems() {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT i.*, u.username as seller_username
            FROM items i
            JOIN users u ON i.seller_id = u.id
            ORDER BY i.created_at DESC
        ");
        $stmt->execute();
        
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'items' => $items
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch items: ' . $e->getMessage()]);
    }
}

// Function to add an item
function addItem() {
    global $conn;
    
    // Check if form data is submitted
    if (!isset($_POST['name']) || empty($_POST['name']) ||
        !isset($_POST['category']) || empty($_POST['category']) ||
        !isset($_POST['price']) || empty($_POST['price']) ||
        !isset($_POST['condition']) || empty($_POST['condition']) ||
        !isset($_POST['seller_id']) || empty($_POST['seller_id'])) {
        
        http_response_code(400);
        echo json_encode(['error' => 'Required fields are missing']);
        return;
    }
    
    // Handle file upload
    $image_url = null;
    if (isset($_FILES['image']) && $_FILES['image']['error'] === 0) {
        $upload_dir = '../uploads/';
        $file_extension = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
        $file_name = uniqid(rand(), true) . '_' . time() . '.' . $file_extension;
        $upload_path = $upload_dir . $file_name;
        
        if (move_uploaded_file($_FILES['image']['tmp_name'], $upload_path)) {
            $image_url = 'uploads/' . $file_name;
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to upload image']);
            return;
        }
    }
    
    // Get seller name using seller_id
    try {
        $seller_stmt = $conn->prepare("SELECT username FROM users WHERE id = :seller_id");
        $seller_stmt->bindParam(':seller_id', $_POST['seller_id']);
        $seller_stmt->execute();
        $seller = $seller_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$seller) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid seller ID']);
            return;
        }
        
        $seller_name = $seller['username'];
        
        // Insert item into database
        $stmt = $conn->prepare("
            INSERT INTO items (name, description, price, category, image_url, `condition`, seller_id, seller_name, is_available)
            VALUES (:name, :description, :price, :category, :image_url, :condition, :seller_id, :seller_name, :is_available)
        ");
        
        $is_available = isset($_POST['is_available']) ? 1 : 0;
        
        $stmt->bindParam(':name', $_POST['name']);
        $stmt->bindParam(':description', $_POST['description']);
        $stmt->bindParam(':price', $_POST['price']);
        $stmt->bindParam(':category', $_POST['category']);
        $stmt->bindParam(':image_url', $image_url);
        $stmt->bindParam(':condition', $_POST['condition']);
        $stmt->bindParam(':seller_id', $_POST['seller_id']);
        $stmt->bindParam(':seller_name', $seller_name);
        $stmt->bindParam(':is_available', $is_available);
        
        $stmt->execute();
        
        $item_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Item added successfully',
            'item_id' => $item_id
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to add item: ' . $e->getMessage()]);
    }
}

// Function to update an item
function updateItem() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Item ID is required']);
        return;
    }
    
    // Build update statement
    $update_fields = [];
    $params = [
        ':id' => $data['id']
    ];
    
    // Fields that can be updated
    $allowed_fields = ['name', 'description', 'price', 'category', 'condition', 'is_available'];
    
    foreach ($allowed_fields as $field) {
        if (isset($data[$field])) {
            $update_fields[] = ($field === 'condition' ? "`condition`" : $field) . " = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    if (empty($update_fields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        return;
    }
    
    try {
        $sql = "UPDATE items SET " . implode(', ', $update_fields) . " WHERE id = :id";
        $stmt = $conn->prepare($sql);
        
        foreach ($params as $param => $value) {
            $stmt->bindValue($param, $value);
        }
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Item updated successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update item: ' . $e->getMessage()]);
    }
}

// Function to delete an item
function deleteItem() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Item ID is required']);
        return;
    }
    
    try {
        // First get the image URL to delete the file
        $stmt = $conn->prepare("SELECT image_url FROM items WHERE id = :id");
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        $item = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($item && !empty($item['image_url'])) {
            $image_path = '../' . $item['image_url'];
            if (file_exists($image_path)) {
                unlink($image_path);
            }
        }
        
        // Delete the item from database
        $stmt = $conn->prepare("DELETE FROM items WHERE id = :id");
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Item deleted successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete item: ' . $e->getMessage()]);
    }
}

// Function to get all events
function getEvents() {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT e.*, u.username as user_username, o.name as outfit_name
            FROM events e
            JOIN users u ON e.user_id = u.id
            LEFT JOIN outfits o ON e.outfit_id = o.id
            ORDER BY e.event_date DESC
        ");
        $stmt->execute();
        
        $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'events' => $events
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch events: ' . $e->getMessage()]);
    }
}

// Function to add an event
function addEvent() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['title']) || empty($data['title']) ||
        !isset($data['event_date']) || empty($data['event_date']) ||
        !isset($data['user_id']) || empty($data['user_id'])) {
        
        http_response_code(400);
        echo json_encode(['error' => 'Required fields are missing']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("
            INSERT INTO events (title, description, event_date, location, outfit_id, user_id)
            VALUES (:title, :description, :event_date, :location, :outfit_id, :user_id)
        ");
        
        $outfit_id = isset($data['outfit_id']) && !empty($data['outfit_id']) ? $data['outfit_id'] : null;
        
        $stmt->bindParam(':title', $data['title']);
        $stmt->bindParam(':description', $data['description']);
        $stmt->bindParam(':event_date', $data['event_date']);
        $stmt->bindParam(':location', $data['location']);
        $stmt->bindParam(':outfit_id', $outfit_id);
        $stmt->bindParam(':user_id', $data['user_id']);
        
        $stmt->execute();
        
        $event_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Event added successfully',
            'event_id' => $event_id
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to add event: ' . $e->getMessage()]);
    }
}

// Function to update an event
function updateEvent() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Event ID is required']);
        return;
    }
    
    // Build update statement
    $update_fields = [];
    $params = [
        ':id' => $data['id']
    ];
    
    // Fields that can be updated
    $allowed_fields = ['title', 'description', 'event_date', 'location', 'outfit_id'];
    
    foreach ($allowed_fields as $field) {
        if (isset($data[$field])) {
            $update_fields[] = "$field = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    if (empty($update_fields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        return;
    }
    
    try {
        $sql = "UPDATE events SET " . implode(', ', $update_fields) . " WHERE id = :id";
        $stmt = $conn->prepare($sql);
        
        foreach ($params as $param => $value) {
            $stmt->bindValue($param, $value);
        }
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Event updated successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update event: ' . $e->getMessage()]);
    }
}

// Function to delete an event
function deleteEvent() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Event ID is required']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("DELETE FROM events WHERE id = :id");
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Event deleted successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete event: ' . $e->getMessage()]);
    }
}

// Function to get statistics
function getStatistics() {
    global $conn;
    
    try {
        // Get user count
        $user_stmt = $conn->prepare("SELECT COUNT(*) as count FROM users");
        $user_stmt->execute();
        $user_count = $user_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Get item count
        $item_stmt = $conn->prepare("SELECT COUNT(*) as count FROM items");
        $item_stmt->execute();
        $item_count = $item_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Get event count
        $event_stmt = $conn->prepare("SELECT COUNT(*) as count FROM events");
        $event_stmt->execute();
        $event_count = $event_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Get donation count (assuming events with donation category)
        $donation_stmt = $conn->prepare("SELECT COUNT(*) as count FROM events WHERE title LIKE '%donate%' OR description LIKE '%donate%'");
        $donation_stmt->execute();
        $donation_count = $donation_stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        // Get user registration trend (past 6 months)
        $user_trend_stmt = $conn->prepare("
            SELECT DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*) as count
            FROM users
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(created_at, '%Y-%m')
            ORDER BY month
        ");
        $user_trend_stmt->execute();
        $user_trend = $user_trend_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get item categories
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
                'event_count' => $event_count,
                'donation_count' => $donation_count,
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
