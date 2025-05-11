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

// Route to appropriate function based on action
if ($action) {
    switch ($action) {
        case 'get_centers':
            if ($method === 'GET') {
                getDonationCenters();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'add_center':
            if ($method === 'POST') {
                // Require admin for adding donation centers
                if (!$user_data || !isset($user_data['role']) || $user_data['role'] !== 'admin') {
                    http_response_code(403);
                    echo json_encode(['error' => 'Admin privileges required']);
                    exit;
                }
                addDonationCenter();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'update_center':
            if ($method === 'PUT') {
                // Require admin for updating donation centers
                if (!$user_data || !isset($user_data['role']) || $user_data['role'] !== 'admin') {
                    http_response_code(403);
                    echo json_encode(['error' => 'Admin privileges required']);
                    exit;
                }
                updateDonationCenter();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'delete_center':
            if ($method === 'DELETE') {
                // Require admin for deleting donation centers
                if (!$user_data || !isset($user_data['role']) || $user_data['role'] !== 'admin') {
                    http_response_code(403);
                    echo json_encode(['error' => 'Admin privileges required']);
                    exit;
                }
                deleteDonationCenter();
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'get_donations':
            if ($method === 'GET') {
                // Get donations that the current user has made or all donations if admin
                getDonations($user_data);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
            
        case 'add_donation':
            if ($method === 'POST') {
                // Any authenticated user can make a donation
                addDonation($user_data);
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

// Function to get all donation centers
function getDonationCenters() {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT id, name, address, contact_info, description, operating_hours, image_url
            FROM donation_centers
            ORDER BY name
        ");
        $stmt->execute();
        
        $centers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'centers' => $centers
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch donation centers: ' . $e->getMessage()]);
    }
}

// Function to add a new donation center (admin only)
function addDonationCenter() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    if (!isset($data['name']) || empty($data['name']) || 
        !isset($data['address']) || empty($data['address'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Name and address are required']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("
            INSERT INTO donation_centers (name, address, contact_info, description, operating_hours, image_url)
            VALUES (:name, :address, :contact_info, :description, :operating_hours, :image_url)
        ");
        
        $stmt->bindParam(':name', $data['name']);
        $stmt->bindParam(':address', $data['address']);
        $stmt->bindParam(':contact_info', $data['contact_info'] ?? null);
        $stmt->bindParam(':description', $data['description'] ?? null);
        $stmt->bindParam(':operating_hours', $data['operating_hours'] ?? null);
        $stmt->bindParam(':image_url', $data['image_url'] ?? null);
        
        $stmt->execute();
        
        $center_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation center added successfully',
            'center_id' => $center_id
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to add donation center: ' . $e->getMessage()]);
    }
}

// Function to update a donation center (admin only)
function updateDonationCenter() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Donation center ID is required']);
        return;
    }
    
    // Build update statement
    $update_fields = [];
    $params = [
        ':id' => $data['id']
    ];
    
    // Fields that can be updated
    $allowed_fields = ['name', 'address', 'contact_info', 'description', 'operating_hours', 'image_url'];
    
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
        $sql = "UPDATE donation_centers SET " . implode(', ', $update_fields) . " WHERE id = :id";
        $stmt = $conn->prepare($sql);
        
        foreach ($params as $param => $value) {
            $stmt->bindValue($param, $value);
        }
        
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation center updated successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update donation center: ' . $e->getMessage()]);
    }
}

// Function to delete a donation center (admin only)
function deleteDonationCenter() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || empty($data['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Donation center ID is required']);
        return;
    }
    
    try {
        $stmt = $conn->prepare("DELETE FROM donation_centers WHERE id = :id");
        $stmt->bindParam(':id', $data['id']);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation center deleted successfully'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete donation center: ' . $e->getMessage()]);
    }
}

// Function to get donations
function getDonations($user_data) {
    global $conn;
    
    try {
        // Check if admin (can see all donations) or regular user (sees only their own)
        $is_admin = isset($user_data['role']) && $user_data['role'] === 'admin';
        
        if ($is_admin) {
            // Admins can see all donations
            $stmt = $conn->prepare("
                SELECT d.*, u.username as donor_name, c.name as center_name
                FROM donations d
                JOIN users u ON d.user_id = u.id
                JOIN donation_centers c ON d.center_id = c.id
                ORDER BY d.donation_date DESC
            ");
            $stmt->execute();
        } else {
            // Regular users see only their own donations
            $stmt = $conn->prepare("
                SELECT d.*, u.username as donor_name, c.name as center_name
                FROM donations d
                JOIN users u ON d.user_id = u.id
                JOIN donation_centers c ON d.center_id = c.id
                WHERE d.user_id = :user_id
                ORDER BY d.donation_date DESC
            ");
            $stmt->bindParam(':user_id', $user_data['user_id']);
            $stmt->execute();
        }
        
        $donations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'donations' => $donations
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch donations: ' . $e->getMessage()]);
    }
}

// Function to add a donation
function addDonation($user_data) {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    if (!isset($data['center_id']) || empty($data['center_id']) || 
        !isset($data['items']) || empty($data['items']) || 
        !isset($data['donation_date']) || empty($data['donation_date'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Center ID, items, and donation date are required']);
        return;
    }
    
    try {
        $conn->beginTransaction();
        
        // Insert donation record
        $stmt = $conn->prepare("
            INSERT INTO donations (user_id, center_id, donation_date, items, notes, status)
            VALUES (:user_id, :center_id, :donation_date, :items, :notes, :status)
        ");
        
        $status = 'pending'; // Default status for new donations
        
        $stmt->bindParam(':user_id', $user_data['user_id']);
        $stmt->bindParam(':center_id', $data['center_id']);
        $stmt->bindParam(':donation_date', $data['donation_date']);
        $stmt->bindParam(':items', $data['items']);
        $stmt->bindParam(':notes', $data['notes'] ?? null);
        $stmt->bindParam(':status', $status);
        
        $stmt->execute();
        
        $donation_id = $conn->lastInsertId();
        
        // If there are specific item IDs that are being donated, mark them as donated in the items table
        if (isset($data['item_ids']) && is_array($data['item_ids'])) {
            $update_item_stmt = $conn->prepare("
                UPDATE items 
                SET is_available = 0, donation_id = :donation_id
                WHERE id = :item_id AND seller_id = :user_id
            ");
            
            foreach ($data['item_ids'] as $item_id) {
                $update_item_stmt->bindParam(':donation_id', $donation_id);
                $update_item_stmt->bindParam(':item_id', $item_id);
                $update_item_stmt->bindParam(':user_id', $user_data['user_id']);
                $update_item_stmt->execute();
            }
        }
        
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation recorded successfully',
            'donation_id' => $donation_id
        ]);
    } catch (PDOException $e) {
        $conn->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to record donation: ' . $e->getMessage()]);
    }
}
?>
