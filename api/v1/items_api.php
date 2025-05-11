<?php
require_once 'error_config.php';
require_once 'headers.php';
require_once 'config.php';

// Set up error handler
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    error_log("Error [$errno] $errstr on line $errline in file $errfile");
    return false;
});

// Set up exception handler
set_exception_handler(function($e) {
    error_log("Uncaught Exception: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Internal Server Error',
        'message' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
    exit;
});

// Get query parameters
$action = isset($_GET['action']) ? $_GET['action'] : null;
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$category = isset($_GET['category']) ? $_GET['category'] : null;

// If action is not set but we have other query parameters, assume it's a get_items request
if (!$action && ($page > 1 || $category)) {
    $action = 'get_items';
}

if ($action) {
    switch ($action) {
        case 'get_items':
            getItems();
            exit;
        case 'get_item':
            $item_id = isset($_GET['id']) ? intval($_GET['id']) : null;
            if ($item_id) {
                getItemById($item_id);
            } else {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Item ID is required']);
            }
            exit;
        case 'search':
            searchItems();
            exit;
        case 'create_item':
            addItem();
            exit;
    }
}

// If no action parameter, continue with the original API structure
// Get the HTTP method and request path
$method = $_SERVER['REQUEST_METHOD'];
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = explode('/', $request);
$endpoint = end($path);

// Extract ID if it exists in URL
$item_id = null;
if (is_numeric($endpoint)) {
    $item_id = intval($endpoint);
    $endpoint = prev($path);
}

// Route to appropriate function based on method and endpoint
switch ($method) {
    case 'GET':
        if ($item_id) {
            getItemById($item_id);
        } else {
            switch ($endpoint) {
                case 'items':
                    getItems();
                    break;
                case 'search':
                    searchItems();
                    break;
                default:
                    http_response_code(404);
                    echo json_encode(['error' => 'Endpoint not found']);
                    break;
            }
        }
        break;
        
    case 'POST':
        switch ($endpoint) {
            case 'items':
                addItem();
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Endpoint not found']);
                break;
        }
        break;
        
    case 'PUT':
        if ($item_id) {
            updateItem($item_id);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Item ID is required for update']);
        }
        break;
        
    case 'DELETE':
        if ($item_id) {
            deleteItem($item_id);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Item ID is required for deletion']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

// Get all items or filter by category, etc.
function getItems() {
    global $conn;
    
    try {
        // Parse query parameters
        $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
        $category = isset($_GET['category']) ? $_GET['category'] : null;
        $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
        
        // Calculate offset
        $offset = ($page - 1) * $limit;
        
        // Log parameters for debugging
        error_log("getItems called with page: $page, limit: $limit, category: $category, user_id: $user_id");
        
        // Build query based on parameters
        $query = "SELECT * FROM items WHERE 1=1";
        $params = [];
        
        if ($category) {
            $query .= " AND category = :category";
            $params[':category'] = $category;
        }
        
        if ($user_id) {
            $query .= " AND user_id = :user_id";
            $params[':user_id'] = $user_id;
        }
        
        $query .= " ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        $params[':limit'] = $limit;
        $params[':offset'] = $offset;
        
        // Log the query for debugging
        error_log("Query: $query with params: " . json_encode($params));
        
        $stmt = $conn->prepare($query);
        foreach ($params as $key => $value) {
            if ($key === ':limit' || $key === ':offset') {
                $stmt->bindValue($key, $value, PDO::PARAM_INT);
            } else {
                $stmt->bindValue($key, $value);
            }
        }
        $stmt->execute();
        
        $items = $stmt->fetchAll();
        
        // Count total items for pagination
        $count_query = "SELECT COUNT(*) FROM items WHERE 1=1";
        if ($category) {
            $count_query .= " AND category = :category";
        }
        if ($user_id) {
            $count_query .= " AND user_id = :user_id";
        }
        
        $count_stmt = $conn->prepare($count_query);
        if ($category) {
            $count_stmt->bindValue(':category', $category);
        }
        if ($user_id) {
            $count_stmt->bindValue(':user_id', $user_id, PDO::PARAM_INT);
        }
        $count_stmt->execute();
        $total_items = $count_stmt->fetchColumn();
        
        // Create response object
        $response = [
            'success' => true,
            'items' => $items,
            'pagination' => [
                'total' => (int)$total_items,
                'page' => (int)$page,
                'limit' => (int)$limit,
                'pages' => ceil($total_items / $limit)
            ]
        ];
        
        // Send response
        header('Content-Type: application/json');
        echo json_encode($response);
        
    } catch (PDOException $e) {
        error_log("PDO Exception in getItems: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Database error',
            'message' => $e->getMessage()
        ]);
    } catch (Exception $e) {
        error_log("General Exception in getItems: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Server error',
            'message' => $e->getMessage()
        ]);
    }
}

// Get item by ID
function getItemById($id) {
    global $conn;
    
    try {
        $stmt = $conn->prepare("SELECT * FROM items WHERE id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
        
        $item = $stmt->fetch();
        
        if ($item) {
            echo json_encode([
                'success' => true,
                'item' => $item
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Item not found']);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch item: ' . $e->getMessage()]);
    }
}

// Add new item
function addItem() {
    global $conn;
    
    error_log("Starting addItem function");
    
    try {
        // Get content type and log all headers for debugging
        $contentType = $_SERVER["CONTENT_TYPE"] ?? '';
        error_log("Content-Type: " . $contentType);
        $headers = getallheaders();
        error_log("All headers: " . json_encode($headers));
        
        // Verify authentication first
        $user_data = verifyAuthentication();
        if (!$user_data) {
            error_log("Authentication failed");
            http_response_code(401);
            echo json_encode(['error' => 'Authentication failed']);
            return;
        }
        error_log("Authentication successful for user_id: " . $user_data['user_id']);
    
    error_log("Authentication successful for user: " . $user_data['user_id']);
    
    // Initialize data array
    $data = [];
    
    // Handle different content types
    error_log("Raw POST data: " . file_get_contents('php://input'));
    error_log("FILES array: " . json_encode($_FILES));
    error_log("POST array: " . json_encode($_POST));
    
    // Handle both multipart and JSON requests
    if (!empty($_FILES)) {
        error_log("Processing multipart form data");
        // Process form fields
        foreach ($_POST as $key => $value) {
            $data[$key] = $value;
            error_log("Form field $key: " . $value);
        }            // Handle file upload if present
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            error_log("Image file received: " . json_encode($_FILES['image']));
            
            // Define upload directory with absolute path and make sure it exists
            $upload_dir = '/Applications/XAMPP/xamppfiles/htdocs/fypProject/uploads/';
            error_log("Upload directory: " . $upload_dir);
            
            // Check upload directory permissions
            if (!is_dir($upload_dir)) {
                if (!mkdir($upload_dir, 0777, true)) {
                    error_log("Failed to create upload directory");
                    http_response_code(500);
                    echo json_encode(['error' => 'Server configuration error: Failed to create upload directory']);
                    return;
                }
                chmod($upload_dir, 0777); // Make sure new directory is writable
                error_log("Created upload directory with permissions 777");
            } else if (!is_writable($upload_dir)) {
                // Try to fix permissions
                chmod($upload_dir, 0777);
                if (!is_writable($upload_dir)) {
                    error_log("Upload directory is not writable even after chmod 777");
                    http_response_code(500);
                    echo json_encode(['error' => 'Server configuration error: Upload directory is not writable']);
                    return;
                }
                error_log("Fixed upload directory permissions");
            }
            
            // Verify file type
            $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mime_type = finfo_file($finfo, $_FILES['image']['tmp_name']);
            finfo_close($finfo);
            
            if (!in_array($mime_type, $allowed_types)) {
                error_log("Invalid file type: " . $mime_type);
                http_response_code(400);
                echo json_encode(['error' => 'Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed.']);
                return;
            }
            
            // Generate a unique filename
            $file_ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            $file_name = uniqid() . '_' . time() . '.' . $file_ext;
            $file_path = $upload_dir . $file_name;
            
            if (move_uploaded_file($_FILES['image']['tmp_name'], $file_path)) {
                error_log("File uploaded successfully to: " . $file_path);
                $data['image_url'] = '/uploads/' . $file_name;
            } else {
                error_log("Failed to move uploaded file. Upload error: " . $_FILES['image']['error']);
                error_log("Destination path: " . $file_path);
                http_response_code(500);
                echo json_encode(['error' => 'Failed to save uploaded file']);
                return;
            }
        }
    } else {
        error_log("Processing JSON data");
        $input = file_get_contents('php://input');
        error_log("Raw input: " . $input);
        $data = json_decode($input, true);
        error_log("Decoded input: " . json_encode($data));
    }
    
    if (empty($data)) {
        error_log("No data received");
        http_response_code(400);
        echo json_encode(['error' => 'No data received']);
        return;
    }
    
    // Log the final data
    error_log("Final data for processing: " . json_encode($data));
    
    // Validate required fields
    $required_fields = ['name', 'description', 'price', 'category', 'condition'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode(['error' => "Missing required field: $field"]);
            return;
        }
    }
    
    error_log("Preparing to insert item with data: " . json_encode($data));
    error_log("User ID for insertion: " . $user_data['user_id']);
    
    // Get the seller name from the user data
    $seller_name = $user_data['username'] ?? 'Unknown Seller';
        
        $stmt = $conn->prepare("
            INSERT INTO items (name, description, price, category, size, color, brand, 
                               image_url, `condition`, seller_id, seller_name)
            VALUES (:name, :description, :price, :category, :size, :color, :brand, 
                    :image_url, :condition, :seller_id, :seller_name)
        ");
        
        // Convert price to numeric if it's a string
        $price = is_string($data['price']) ? floatval($data['price']) : $data['price'];
        
        // If any of these fields are missing, use default values
        $size = $data['size'] ?? 'One Size';
        $color = $data['color'] ?? 'Not specified';
        $brand = $data['brand'] ?? 'Unbranded';
        $image_url = $data['image_url'] ?? null;
        
        $stmt->bindParam(':name', $data['name'], PDO::PARAM_STR);
        $stmt->bindParam(':description', $data['description'], PDO::PARAM_STR);
        $stmt->bindParam(':price', $price);
        $stmt->bindParam(':category', $data['category'], PDO::PARAM_STR);
        $stmt->bindParam(':size', $size, PDO::PARAM_STR);
        $stmt->bindParam(':color', $color, PDO::PARAM_STR);
        $stmt->bindParam(':brand', $brand, PDO::PARAM_STR);
        $stmt->bindParam(':image_url', $image_url, PDO::PARAM_STR);
        $stmt->bindParam(':condition', $data['condition'], PDO::PARAM_STR);
        $stmt->bindParam(':seller_id', $user_data['user_id'], PDO::PARAM_INT);
        $stmt->bindParam(':seller_name', $seller_name, PDO::PARAM_STR);
        
        $stmt->execute();
        error_log("Item inserted successfully");
        
        $item_id = $conn->lastInsertId();
        error_log("New item ID: " . $item_id);
        
        echo json_encode([
            'success' => true,
            'message' => 'Item added successfully',
            'item_id' => $item_id
        ]);
    } catch (PDOException $e) {
        error_log("Database error in addItem: " . $e->getMessage());
        error_log("SQL State: " . $e->getCode());
        error_log("Stack trace: " . $e->getTraceAsString());
        http_response_code(500);
        echo json_encode([
            'error' => 'Failed to add item',
            'details' => $e->getMessage(),
            'code' => $e->getCode()
        ]);
    }
}

// Update item
function updateItem($id) {
    global $conn;
    
    // Check authorization
    $user_data = verifyAuthentication();
    if (!$user_data) {
        return;
    }
    
    // Check if item exists and belongs to the user
    $stmt = $conn->prepare("SELECT seller_id FROM items WHERE id = :id");
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();
    $item = $stmt->fetch();
    
    if (!$item) {
        http_response_code(404);
        echo json_encode(['error' => 'Item not found']);
        return;
    }
    
    // Check if the user is the seller or an admin
    $is_admin = isset($user_data['role']) && $user_data['role'] === 'admin';
    if ($item['seller_id'] != $user_data['user_id'] && !$is_admin) {
        http_response_code(403);
        echo json_encode(['error' => 'You do not have permission to update this item']);
        return;
    }
    
    // Get JSON data from request body
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Build update SQL dynamically based on provided fields
    $updateFields = [];
    $params = [':id' => $id];
    
    $allowedFields = [
        'name', 'description', 'price', 'category', 'condition_value',
        'brand', 'size', 'color', 'image_url', 'status'
    ];
    
    foreach ($allowedFields as $field) {
        if (isset($data[$field])) {
            $updateFields[] = "$field = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    // If no fields to update
    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No fields to update']);
        return;
    }
    
    $updateFields[] = "updated_at = NOW()";
    
    try {
        $sql = "UPDATE items SET " . implode(', ', $updateFields) . " WHERE id = :id";
        $stmt = $conn->prepare($sql);
        
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Item updated successfully',
            'updated_fields' => array_keys($data)
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update item: ' . $e->getMessage()]);
    }
}

// Delete item
function deleteItem($id) {
    global $conn;
    
    // Check authorization
    $user_data = verifyAuthentication();
    if (!$user_data) {
        return;
    }
    
    // Check if item exists and belongs to the user
    $stmt = $conn->prepare("SELECT seller_id FROM items WHERE id = :id");
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();
    $item = $stmt->fetch();
    
    if (!$item) {
        http_response_code(404);
        echo json_encode(['error' => 'Item not found']);
        return;
    }
    
    // Check if the user is the seller or an admin
    $is_admin = isset($user_data['role']) && $user_data['role'] === 'admin';
    if ($item['seller_id'] != $user_data['user_id'] && !$is_admin) {
        http_response_code(403);
        echo json_encode(['error' => 'You do not have permission to delete this item']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("DELETE FROM items WHERE id = :id");
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
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

// Search items
function searchItems() {
    global $conn;
    
    $query = isset($_GET['q']) ? $_GET['q'] : '';
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
    
    try {
        $sql = "
            SELECT * FROM items 
            WHERE name LIKE :query 
            OR description LIKE :query 
            OR category LIKE :query 
            OR brand LIKE :query
            ORDER BY created_at DESC
            LIMIT :limit OFFSET :offset
        ";
        
        $stmt = $conn->prepare($sql);
        $search_term = "%$query%";
        $stmt->bindParam(':query', $search_term);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $items = $stmt->fetchAll();
        
        // Count total results
        $count_sql = "
            SELECT COUNT(*) FROM items 
            WHERE name LIKE :query 
            OR description LIKE :query 
            OR category LIKE :query 
            OR brand LIKE :query
        ";
        
        $count_stmt = $conn->prepare($count_sql);
        $count_stmt->bindParam(':query', $search_term);
        $count_stmt->execute();
        $total_items = $count_stmt->fetchColumn();
        
        echo json_encode([
            'success' => true,
            'items' => $items,
            'query' => $query,
            'pagination' => [
                'total' => $total_items,
                'limit' => $limit,
                'offset' => $offset
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Search failed: ' . $e->getMessage()]);
    }
}

// Helper function to verify authentication
function verifyAuthentication() {
    error_log("Starting authentication verification");
    
    // Get all headers
    $headers = getallheaders();
    error_log("All headers received: " . json_encode($headers));
    
    // Normalize header names to handle case-insensitive matching
    $normalizedHeaders = array_change_key_case($headers, CASE_LOWER);
    error_log("Normalized headers: " . json_encode($normalizedHeaders));
    
    // Check for Authorization header (case-insensitive)
    if (!isset($normalizedHeaders['authorization'])) {
        error_log("No Authorization header found in normalized headers");
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        return null;
    }
    
    $auth_header = $normalizedHeaders['authorization'];
    error_log("Found Authorization header: " . $auth_header);
    
    if (strpos($auth_header, 'Bearer ') !== 0) {
        error_log("Invalid token format - header doesn't start with 'Bearer '");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        return null;
    }
    
    $token = substr($auth_header, 7);
    error_log("Extracted token: " . $token);
    
    $user_data = verifyToken($token);
    error_log("Token verification result: " . json_encode($user_data));
    
    if (!$user_data) {
        error_log("Token verification failed");
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        return null;
    }
    
    error_log("Authentication successful for user: " . json_encode($user_data));
    return $user_data;
}
?>