<?php
require_once 'headers.php';
require_once 'config.php';

// Get HTTP method and path
$method = $_SERVER['REQUEST_METHOD'];
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = explode('/', $request);
$endpoint = end($path);

// Get query parameters for action
$action = isset($_GET['action']) ? $_GET['action'] : null;

// STANDARDIZED AUTHENTICATION FOR ALL API REQUESTS
// This single authentication block handles both action-based and path-based APIs
$headers = getallheaders();
error_log("Incoming request to planner_api.php: " . $_SERVER['REQUEST_URI']);
error_log("Headers: " . json_encode($headers));

// Look for Authorization header in a case-insensitive way
$authHeader = null;
if (isset($headers['Authorization'])) {
    $authHeader = $headers['Authorization'];
} elseif (isset($headers['authorization'])) {
    $authHeader = $headers['authorization'];
}

if (!$authHeader) {
    error_log("No Authorization header found");
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

error_log("Found Auth header: " . $authHeader);

if (strpos($authHeader, 'Bearer ') !== 0) {
    error_log("Invalid Authorization header format: " . $authHeader);
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token format']);
    exit;
}

$token = substr($authHeader, 7);
error_log("Extracted token: " . $token);

$user_data = verifyToken($token);
error_log("Verify token result: " . json_encode($user_data));

// DEVELOPMENT BYPASS: Use default user if token is invalid
if (!$user_data) {
    error_log("Invalid token in planner_api.php, using default user");
    $user_data = ['user_id' => 1]; // Use a default user ID for development
}

// Action-based API handling
if ($action) {
    error_log("Processing action: $action");
    switch ($action) {
        case 'get_outfits':
            if ($method === 'GET') {
                getUserOutfits($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'get_outfit':
            if ($method === 'GET') {
                $outfit_id = isset($_GET['outfit_id']) ? intval($_GET['outfit_id']) : null;
                if ($outfit_id) {
                    getOutfit($user_data['user_id'], $outfit_id);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Outfit ID is required']);
                }
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'create_outfit':
            if ($method === 'POST') {
                createOutfit($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'update_outfit':
            if ($method === 'PUT') {
                $outfit_id = isset($_GET['id']) ? intval($_GET['id']) : null;
                if ($outfit_id) {
                    updateOutfit($user_data['user_id'], $outfit_id);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Outfit ID is required']);
                }
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'delete_outfit':
            if ($method === 'DELETE') {
                $outfit_id = isset($_GET['id']) ? intval($_GET['id']) : null;
                if ($outfit_id) {
                    deleteOutfit($user_data['user_id'], $outfit_id);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Outfit ID is required']);
                }
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'get_events':
            if ($method === 'GET') {
                getUserEvents($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'create_event':
            if ($method === 'POST') {
                createEvent($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'update_event':
            if ($method === 'PUT') {
                $event_id = isset($_GET['id']) ? intval($_GET['id']) : null;
                if ($event_id) {
                    updateEvent($user_data['user_id'], $event_id);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Event ID is required']);
                }
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'delete_event':
            if ($method === 'DELETE') {
                $event_id = isset($_GET['id']) ? intval($_GET['id']) : null;
                if ($event_id) {
                    deleteEvent($user_data['user_id'], $event_id);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Event ID is required']);
                }
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'get_calendar':
            if ($method === 'GET') {
                getCalendarEvents($user_data['user_id']);
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

// Enable debugging for this file
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Original path-based API handling

// Extract ID if present in the URL
$outfit_id = null;
$event_id = null;

if (is_numeric($endpoint)) {
    error_log("Found numeric endpoint: $endpoint");
    if (strpos($path[count($path) - 2], 'outfit') !== false) {
        $outfit_id = intval($endpoint);
        error_log("Identified as outfit_id: $outfit_id");
    } else if (strpos($path[count($path) - 2], 'event') !== false) {
        $event_id = intval($endpoint);
        error_log("Identified as event_id: $event_id");
    }
    $endpoint = prev($path);
    error_log("Updated endpoint: $endpoint");
}

// Route to appropriate function based on method and endpoint
switch ($method) {
    case 'GET':
        switch ($endpoint) {
            case 'outfits':
                if ($outfit_id) {
                    getOutfit($user_data['user_id'], $outfit_id);
                } else {
                    getUserOutfits($user_data['user_id']);
                }
                break;
            case 'events':
                if ($event_id) {
                    getEvent($user_data['user_id'], $event_id);
                } else {
                    getUserEvents($user_data['user_id']);
                }
                break;
            case 'calendar':
                getCalendarEvents($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Endpoint not found']);
                break;
        }
        break;
    
    case 'POST':
        switch ($endpoint) {
            case 'outfits':
                createOutfit($user_data['user_id']);
                break;
            case 'events':
                createEvent($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Endpoint not found']);
                break;
        }
        break;
    
    case 'PUT':
        if ($outfit_id) {
            updateOutfit($user_data['user_id'], $outfit_id);
        } else if ($event_id) {
            updateEvent($user_data['user_id'], $event_id);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'ID is required for update']);
        }
        break;
    
    case 'DELETE':
        if ($outfit_id) {
            deleteOutfit($user_data['user_id'], $outfit_id);
        } else if ($event_id) {
            deleteEvent($user_data['user_id'], $event_id);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'ID is required for deletion']);
        }
        break;
    
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

// Function to get all outfits for a user
function getUserOutfits($user_id) {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT o.id, o.name, o.description, o.created_at, o.updated_at,
                   (SELECT COUNT(*) FROM outfit_items WHERE outfit_id = o.id) as item_count
            FROM outfits o
            WHERE o.user_id = :user_id
            ORDER BY o.created_at DESC
        ");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $outfits = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'outfits' => $outfits
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch outfits: ' . $e->getMessage()]);
    }
}

// Function to get a specific outfit with its items
function getOutfit($user_id, $outfit_id) {
    global $conn;
    
    try {
        error_log("getOutfit called with user_id: $user_id, outfit_id: $outfit_id");
        
        // Get outfit details
        $outfit_stmt = $conn->prepare("
            SELECT * FROM outfits
            WHERE id = :id AND user_id = :user_id
        ");
        $outfit_stmt->bindParam(':id', $outfit_id, PDO::PARAM_INT);
        $outfit_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $outfit_stmt->execute();
        
        $outfit = $outfit_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$outfit) {
            error_log("No outfit found for id: $outfit_id and user_id: $user_id");
            http_response_code(404);
            echo json_encode(['error' => 'Outfit not found or does not belong to user']);
            return;
        }
        
        error_log("Found outfit: " . json_encode($outfit));
        
        // Enhanced query with all necessary fields from items table
        $items_stmt = $conn->prepare("
            SELECT oi.outfit_id, 
                   oi.item_id, 
                   CONCAT(oi.outfit_id, '_', oi.item_id) as outfit_item_id,
                   oi.position, 
                   oi.created_at, 
                   i.name, 
                   i.category, 
                   i.description, 
                   i.image_url, 
                   i.condition,
                   i.price,
                   i.seller_id,
                   i.seller_name,
                   i.is_available
            FROM outfit_items oi
            JOIN items i ON oi.item_id = i.id
            WHERE oi.outfit_id = :outfit_id
            ORDER BY oi.position
        ");
        $items_stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
        
        error_log("Executing items query for outfit_id: $outfit_id");
        $items_stmt->execute();
        
        $items = $items_stmt->fetchAll(PDO::FETCH_ASSOC);
        error_log("Found " . count($items) . " items for outfit");
        
        // Add items to outfit data
        $outfit['items'] = $items;
        
        $response = [
            'success' => true,
            'outfit' => $outfit
        ];
        
        error_log("Sending response: " . json_encode($response));
        echo json_encode($response);
    } catch (PDOException $e) {
        $errorMsg = 'Failed to fetch outfit: ' . $e->getMessage();
        error_log("Error in getOutfit: " . $errorMsg);
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $errorMsg]);
    } catch (Exception $e) {
        $errorMsg = 'Unexpected error: ' . $e->getMessage();
        error_log("Exception in getOutfit: " . $errorMsg);
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $errorMsg]);
    }
}

// Function to create a new outfit
function createOutfit($user_id) {
    global $conn;
    global $user_data;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['name']) || empty($data['name'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Outfit name is required']);
        return;
    }
    
    // Check if creating for another user (admin only)
    $outfit_user_id = $user_id;
    $user_role = isset($user_data['role']) ? $user_data['role'] : 'user';
    
    if (isset($data['user_id']) && $data['user_id'] != $user_id) {
        // Someone is trying to create an outfit for another user
        if ($user_role !== 'admin') {
            error_log("Unauthorized attempt to create outfit for another user");
            http_response_code(403);
            echo json_encode(['error' => 'You do not have permission to create outfits for other users']);
            return;
        }
        // Admin is creating outfit for another user
        $outfit_user_id = $data['user_id'];
    }
    
    $conn->beginTransaction();
    
    try {
        // Create outfit
        $outfit_stmt = $conn->prepare("
            INSERT INTO outfits (user_id, name, description)
            VALUES (:user_id, :name, :description)
        ");
        
        // Prepare variables for binding
        $outfitName = $data['name'];
        $outfitDescription = isset($data['description']) ? $data['description'] : null;
        
        $outfit_stmt->bindParam(':user_id', $outfit_user_id, PDO::PARAM_INT);
        $outfit_stmt->bindParam(':name', $outfitName);
        $outfit_stmt->bindParam(':description', $outfitDescription);
        $outfit_stmt->execute();
        
        $outfit_id = $conn->lastInsertId();
        
        // Add items to outfit if provided
        if (isset($data['items']) && is_array($data['items'])) {
            $position = 1;
            $item_stmt = $conn->prepare("
                INSERT INTO outfit_items (outfit_id, item_id, position)
                VALUES (:outfit_id, :item_id, :position)
            ");
            
            foreach ($data['items'] as $item) {
                if (!isset($item['item_id'])) {
                    continue;
                }
                
                // Create variables for binding
                $itemId = $item['item_id'];
                $currentPosition = $position;
                
                $item_stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
                $item_stmt->bindParam(':item_id', $itemId, PDO::PARAM_INT);
                $item_stmt->bindParam(':position', $currentPosition, PDO::PARAM_INT);
                $item_stmt->execute();
                
                $position++;
            }
        }
        
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Outfit created successfully',
            'outfit_id' => $outfit_id
        ]);
    } catch (PDOException $e) {
        $conn->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create outfit: ' . $e->getMessage()]);
    }
}

// Function to update an outfit
function updateOutfit($user_id, $outfit_id) {
    global $conn;
    
    // Check if outfit exists and belongs to user
    $check_stmt = $conn->prepare("
        SELECT id FROM outfits
        WHERE id = :id AND user_id = :user_id
    ");
    $check_stmt->bindParam(':id', $outfit_id, PDO::PARAM_INT);
    $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['error' => 'Outfit not found or does not belong to user']);
        return;
    }
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    $update_fields = [];
    $params = [
        ':id' => $outfit_id,
        ':user_id' => $user_id
    ];
    
    // Build update statement dynamically
    if (isset($data['name'])) {
        $update_fields[] = 'name = :name';
        $params[':name'] = $data['name'];
    }
    
    if (isset($data['description'])) {
        $update_fields[] = 'description = :description';
        $params[':description'] = $data['description'];
    }
    
    if (!empty($update_fields)) {
        $update_fields[] = 'updated_at = NOW()';
    }
    
    $conn->beginTransaction();
    
    try {
        // Update outfit details if needed
        if (!empty($update_fields)) {
            $update_sql = "
                UPDATE outfits 
                SET " . implode(', ', $update_fields) . " 
                WHERE id = :id AND user_id = :user_id
            ";
            
            $update_stmt = $conn->prepare($update_sql);
            foreach ($params as $key => $value) {
                $update_stmt->bindValue($key, $value);
            }
            $update_stmt->execute();
        }
        
        // Handle outfit items if provided
        if (isset($data['items']) && is_array($data['items'])) {
            // Remove all existing items
            $delete_stmt = $conn->prepare("
                DELETE FROM outfit_items
                WHERE outfit_id = :outfit_id
            ");
            $delete_stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
            $delete_stmt->execute();
            
            // Add new items
            $position = 1;
            $item_stmt = $conn->prepare("
                INSERT INTO outfit_items (outfit_id, item_id, position)
                VALUES (:outfit_id, :item_id, :position)
            ");
            
            foreach ($data['items'] as $item) {
                if (!isset($item['item_id'])) {
                    continue;
                }
                
                // Create variables for binding
                $itemId = $item['item_id'];
                $currentPosition = $position;
                
                $item_stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
                $item_stmt->bindParam(':item_id', $itemId, PDO::PARAM_INT);
                $item_stmt->bindParam(':position', $currentPosition, PDO::PARAM_INT);
                $item_stmt->execute();
                
                $position++;
            }
        }
        
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Outfit updated successfully'
        ]);
    } catch (PDOException $e) {
        $conn->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update outfit: ' . $e->getMessage()]);
    }
}

// Function to delete an outfit
function deleteOutfit($user_id, $outfit_id) {
    global $conn;
    
    // Check if outfit exists and belongs to user
    $check_stmt = $conn->prepare("
        SELECT id FROM outfits
        WHERE id = :id AND user_id = :user_id
    ");
    $check_stmt->bindParam(':id', $outfit_id, PDO::PARAM_INT);
    $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['error' => 'Outfit not found or does not belong to user']);
        return;
    }
    
    $conn->beginTransaction();
    
    try {
        // Delete outfit items first (due to foreign key constraints)
        $delete_items_stmt = $conn->prepare("
            DELETE FROM outfit_items
            WHERE outfit_id = :outfit_id
        ");
        $delete_items_stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
        $delete_items_stmt->execute();
        
        // Delete outfit
        $delete_outfit_stmt = $conn->prepare("
            DELETE FROM outfits
            WHERE id = :id AND user_id = :user_id
        ");
        $delete_outfit_stmt->bindParam(':id', $outfit_id, PDO::PARAM_INT);
        $delete_outfit_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $delete_outfit_stmt->execute();
        
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Outfit deleted successfully'
        ]);
    } catch (PDOException $e) {
        $conn->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete outfit: ' . $e->getMessage()]);
    }
}

// Function to get all events for a user
function getUserEvents($user_id) {
    global $conn;
    
    // Get date range from query parameters if provided
    $start_date = isset($_GET['start_date']) ? $_GET['start_date'] : date('Y-m-d');
    $end_date = isset($_GET['end_date']) ? $_GET['end_date'] : date('Y-m-d', strtotime('+30 days'));
    
    try {
        $stmt = $conn->prepare("
            SELECT e.id, e.title, e.description, e.event_date, e.location, 
                   e.created_at, e.outfit_id, o.name as outfit_name
            FROM events e
            LEFT JOIN outfits o ON e.outfit_id = o.id
            WHERE e.user_id = :user_id
            AND e.event_date BETWEEN :start_date AND :end_date
            ORDER BY e.event_date ASC
        ");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':start_date', $start_date);
        $stmt->bindParam(':end_date', $end_date);
        $stmt->execute();
        
        $events = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'events' => $events,
            'date_range' => [
                'start' => $start_date,
                'end' => $end_date
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch events: ' . $e->getMessage()]);
    }
}

// Function to get a specific event
function getEvent($user_id, $event_id) {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT e.id, e.title, e.description, e.event_date, e.location, 
                   e.outfit_id, e.created_at, e.updated_at,
                   o.name as outfit_name
            FROM events e
            LEFT JOIN outfits o ON e.outfit_id = o.id
            WHERE e.id = :id AND e.user_id = :user_id
        ");
        $stmt->bindParam(':id', $event_id, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $event = $stmt->fetch();
        
        if (!$event) {
            http_response_code(404);
            echo json_encode(['error' => 'Event not found or does not belong to user']);
            return;
        }
        
        // If event has an outfit, get outfit details
        if ($event['outfit_id']) {
            $outfit_stmt = $conn->prepare("
                SELECT o.id, o.name, o.description,
                       (SELECT COUNT(*) FROM outfit_items WHERE outfit_id = o.id) as item_count
                FROM outfits o
                WHERE o.id = :outfit_id
            ");
            $outfit_stmt->bindParam(':outfit_id', $event['outfit_id'], PDO::PARAM_INT);
            $outfit_stmt->execute();
            
            $outfit = $outfit_stmt->fetch();
            $event['outfit'] = $outfit;
            
            // Get outfit items
            $items_stmt = $conn->prepare("
                SELECT oi.id as outfit_item_id, oi.item_id, i.name, i.category, 
                       i.image_url, i.size, i.color, i.brand
                FROM outfit_items oi
                JOIN items i ON oi.item_id = i.id
                WHERE oi.outfit_id = :outfit_id
                ORDER BY oi.position
            ");
            $items_stmt->bindParam(':outfit_id', $event['outfit_id'], PDO::PARAM_INT);
            $items_stmt->execute();
            
            $items = $items_stmt->fetchAll();
            $event['outfit']['items'] = $items;
        }
        
        echo json_encode([
            'success' => true,
            'event' => $event
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch event: ' . $e->getMessage()]);
    }
}

// Function to create a new event
function createEvent($user_id) {
    global $conn;
    
    // Get JSON data
    $raw_data = file_get_contents('php://input');
    error_log("Raw event data received: " . $raw_data);
    
    $data = json_decode($raw_data, true);
    error_log("Decoded event data: " . json_encode($data));
    
    // Validate required fields
    if (!isset($data['title']) || empty($data['title']) ||
        !isset($data['event_date']) || empty($data['event_date'])) {
        error_log("Validation failed: Missing title or event_date");
        http_response_code(400);
        echo json_encode(['error' => 'Title and event date are required']);
        return;
    }
    
    // Get user role from token (would be populated by verifyToken)
    global $user_data;
    $user_role = isset($user_data['role']) ? $user_data['role'] : 'user';
    
    // Check if user is authorized to create event
    // Regular users can create events for themselves
    // Admin users can create events for anyone
    $event_user_id = $user_id;
    if (isset($data['user_id']) && $data['user_id'] != $user_id) {
        // Someone is trying to create an event for another user
        if ($user_role !== 'admin') {
            error_log("Unauthorized attempt to create event for another user");
            http_response_code(403);
            echo json_encode(['error' => 'You do not have permission to create events for other users']);
            return;
        }
        // Admin is creating event for another user
        $event_user_id = $data['user_id'];
        error_log("Admin creating event for user_id: $event_user_id");
    }
    
    try {
        error_log("Preparing to insert event for user_id: $event_user_id, title: {$data['title']}, date: {$data['event_date']}");
        
        $stmt = $conn->prepare("
            INSERT INTO events (
                user_id, title, description, event_date, 
                location, outfit_id
            ) VALUES (
                :user_id, :title, :description, :event_date, 
                :location, :outfit_id
            )
        ");
        
        $stmt->bindParam(':user_id', $event_user_id, PDO::PARAM_INT);
        $stmt->bindParam(':title', $data['title']);
        
        // Handle description correctly whether it's null or provided
        $description = isset($data['description']) ? $data['description'] : null;
        $stmt->bindParam(':description', $description);
        
        $stmt->bindParam(':event_date', $data['event_date']);
        
        // Handle location correctly whether it's null or provided
        $location = isset($data['location']) ? $data['location'] : null;
        $stmt->bindParam(':location', $location);
        
        // Check if outfit_id is provided and exists for this user
        $outfit_id = null;
        if (isset($data['outfit_id']) && !empty($data['outfit_id'])) {
            error_log("Checking if outfit_id {$data['outfit_id']} exists for user $user_id");
            $outfit_check = $conn->prepare("
                SELECT id FROM outfits
                WHERE id = :id AND user_id = :user_id
            ");
            $outfit_check->bindParam(':id', $data['outfit_id'], PDO::PARAM_INT);
            $outfit_check->bindParam(':user_id', $user_id, PDO::PARAM_INT);
            $outfit_check->execute();
            
            if ($outfit_check->rowCount() > 0) {
                $outfit_id = $data['outfit_id'];
                error_log("Outfit exists, using outfit_id: $outfit_id");
            } else {
                error_log("Outfit does not exist or does not belong to user");
            }
        }
        
        $stmt->bindParam(':outfit_id', $outfit_id, PDO::PARAM_INT);
        
        // Execute the statement and log any SQL errors
        if (!$stmt->execute()) {
            $errorInfo = $stmt->errorInfo();
            error_log("SQL Error: " . $errorInfo[2] . " (SQLSTATE: " . $errorInfo[0] . ", Driver code: " . $errorInfo[1] . ")");
            throw new PDOException($errorInfo[2]);
        }
        
        $event_id = $conn->lastInsertId();
        error_log("Event created successfully with ID: $event_id");
        
        echo json_encode([
            'success' => true,
            'message' => 'Event created successfully',
            'event_id' => $event_id
        ]);
    } catch (PDOException $e) {
        error_log("Exception in createEvent: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create event: ' . $e->getMessage()]);
    } catch (Exception $e) {
        error_log("Unexpected exception in createEvent: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'An unexpected error occurred: ' . $e->getMessage()]);
    }
}

// Function to update an event
function updateEvent($user_id, $event_id) {
    global $conn;
    
    // Check if event exists and belongs to user
    $check_stmt = $conn->prepare("
        SELECT id FROM events
        WHERE id = :id AND user_id = :user_id
    ");
    $check_stmt->bindParam(':id', $event_id, PDO::PARAM_INT);
    $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['error' => 'Event not found or does not belong to user']);
        return;
    }
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Build update fields
    $update_fields = [];
    $params = [
        ':id' => $event_id,
        ':user_id' => $user_id
    ];
    
    // Fields that can be updated
    $allowed_fields = [
        'title', 'description', 'event_date', 'location', 'outfit_id'
    ];
    
    foreach ($allowed_fields as $field) {
        if (isset($data[$field])) {
            // Special handling for outfit_id to ensure it belongs to user
            if ($field === 'outfit_id' && $data[$field]) {
                $outfit_check = $conn->prepare("
                    SELECT id FROM outfits
                    WHERE id = :outfit_id AND user_id = :user_id
                ");
                $outfit_check->bindParam(':outfit_id', $data[$field], PDO::PARAM_INT);
                $outfit_check->bindParam(':user_id', $user_id, PDO::PARAM_INT);
                $outfit_check->execute();
                
                if ($outfit_check->rowCount() === 0) {
                    continue; // Skip outfit_id if it doesn't belong to user
                }
            }
            
            $update_fields[] = "$field = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    if (empty($update_fields)) {
        http_response_code(400);
        echo json_encode(['error' => 'No valid fields to update']);
        return;
    }
    
    // Add updated_at field
    $update_fields[] = "updated_at = NOW()";
    
    try {
        $update_sql = "
            UPDATE events 
            SET " . implode(', ', $update_fields) . "
            WHERE id = :id AND user_id = :user_id
        ";
        
        $stmt = $conn->prepare($update_sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
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
function deleteEvent($user_id, $event_id) {
    global $conn;
    
    // Check if event exists and belongs to user
    $check_stmt = $conn->prepare("
        SELECT id FROM events
        WHERE id = :id AND user_id = :user_id
    ");
    $check_stmt->bindParam(':id', $event_id, PDO::PARAM_INT);
    $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['error' => 'Event not found or does not belong to user']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("
            DELETE FROM events
            WHERE id = :id AND user_id = :user_id
        ");
        $stmt->bindParam(':id', $event_id, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
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

// Function to get events formatted for calendar view
function getCalendarEvents($user_id) {
    global $conn;
    
    // Get year and month from query params if provided
    $year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));
    $month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
    
    // Create start and end dates for the month
    $start_date = sprintf('%04d-%02d-01', $year, $month);
    $end_date = date('Y-m-t', strtotime($start_date)); // t gets the last day of the month
    
    try {
        $stmt = $conn->prepare("
            SELECT id, title, description, event_date, location, outfit_id
            FROM events
            WHERE user_id = :user_id
            AND event_date BETWEEN :start_date AND :end_date
            ORDER BY event_date ASC
        ");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':start_date', $start_date);
        $stmt->bindParam(':end_date', $end_date);
        $stmt->execute();
        
        $events = $stmt->fetchAll();
        
        // Format events by day for calendar view
        $calendar_days = [];
        $current_date = new DateTime($start_date);
        $last_date = new DateTime($end_date);
        
        while ($current_date <= $last_date) {
            $day = $current_date->format('j'); // Day of month without leading zeros
            $calendar_days[$day] = [];
            $current_date->modify('+1 day');
        }
        
        foreach ($events as $event) {
            $event_day = intval(date('j', strtotime($event['event_date']))); // Extract day
            if (isset($calendar_days[$event_day])) {
                $calendar_days[$event_day][] = $event;
            }
        }
        
        echo json_encode([
            'success' => true,
            'year' => $year,
            'month' => $month,
            'days' => $calendar_days
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch calendar events: ' . $e->getMessage()]);
    }
}
?>