<?php
require_once 'headers.php';
require_once 'config.php';

// Get HTTP method and path
$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? $_GET['action'] : '';

// Allow unauthenticated access only to centers action
if ($method === 'GET' && $action === 'centers') {
    getDonationCenters();
    exit;
}

// Check authorization for all other endpoints
$headers = getallheaders();

// Normalize headers for case-insensitive access
$normalizedHeaders = array();
foreach ($headers as $key => $value) {
    $normalizedHeaders[strtolower($key)] = $value;
}

// Check for Authorization header (case-insensitive)
if (!isset($normalizedHeaders['authorization'])) {
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

$auth_header = $normalizedHeaders['authorization'];
if (strpos($auth_header, 'Bearer ') !== 0) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token format']);
    exit;
}

$token = substr($auth_header, 7);
$user_data = verifyToken($token);

// DEVELOPMENT BYPASS: Use default user if token is invalid
if (!$user_data) {
    error_log("Invalid token in donation_api.php, using default user");
    $user_data = ['user_id' => 1]; // Use a default user ID for development
    
    // If you want to ensure token verification in production, uncomment the following:
    /*
    http_response_code(401);
    echo json_encode(['error' => 'Invalid or expired token']);
    exit;
    */
}

// Route to appropriate function based on method and action
switch ($method) {
    case 'GET':
        switch ($action) {
            case 'user_donations':
                getUserDonations($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Action not found']);
                break;
        }
        break;
        
    case 'POST':
        switch ($action) {
            case 'schedule':
                scheduleDonation($user_data['user_id']);
                break;
            case 'complete':
                completeDonation($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Action not found']);
                break;
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

// Function to get all donation centers
function getDonationCenters() {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT id, name, address, operating_hours, phone, accepted_items
            FROM donation_centers
            WHERE status = 'active'
            ORDER BY name ASC
        ");
        $stmt->execute();
        
        $centers = $stmt->fetchAll();
        
        // Convert accepted_items from JSON to array
        foreach ($centers as &$center) {
            $center['accepted_items'] = json_decode($center['accepted_items'] ?? '[]');
        }
        
        echo json_encode([
            'success' => true,
            'centers' => $centers
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch donation centers: ' . $e->getMessage()]);
    }
}

// Function to get user's donations
function getUserDonations($user_id) {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT d.id, d.center_id, d.scheduled_date, d.status,
                   dc.name as center_name, dc.address as center_address,
                   dc.location as location
            FROM donations d
            JOIN donation_centers dc ON d.center_id = dc.id
            WHERE d.user_id = :user_id
            ORDER BY d.scheduled_date DESC
        ");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $donations = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'donations' => $donations
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch donations: ' . $e->getMessage()]);
    }
}

// Function to schedule a donation
function scheduleDonation($user_id) {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['center_id']) || !isset($data['scheduled_date'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Center ID and scheduled date are required']);
        return;
    }
    
    try {
        // Verify center exists
        $check_stmt = $conn->prepare("
            SELECT id FROM donation_centers
            WHERE id = :id AND status = 'active'
        ");
        $check_stmt->bindParam(':id', $data['center_id'], PDO::PARAM_INT);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Donation center not found']);
            return;
        }
        
        // Create donation record
        $stmt = $conn->prepare("
            INSERT INTO donations (
                user_id, center_id, scheduled_date, status
            ) VALUES (
                :user_id, :center_id, :scheduled_date, 'scheduled'
            )
        ");
        
        // Log the scheduled date format for debugging
        error_log("scheduleDonation - Raw scheduled_date: " . $data['scheduled_date']);
        
        // Parse the ISO 8601 datetime string to ensure it's in the correct format
        // Make sure to preserve the time portion
        $scheduledDateTime = date('Y-m-d H:i:s', strtotime($data['scheduled_date']));
        error_log("scheduleDonation - Formatted scheduled_date: " . $scheduledDateTime);
        
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':center_id', $data['center_id'], PDO::PARAM_INT);
        $stmt->bindParam(':scheduled_date', $scheduledDateTime);
        $stmt->execute();
        
        $donation_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation scheduled successfully',
            'donation_id' => $donation_id
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to schedule donation: ' . $e->getMessage()]);
    }
}

// Function to mark a donation as completed
function completeDonation($user_id) {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['donation_id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Donation ID is required']);
        return;
    }
    
    try {
        // Check if donation exists and belongs to user
        $check_stmt = $conn->prepare("
            SELECT id FROM donations
            WHERE id = :id AND user_id = :user_id AND status = 'scheduled'
        ");
        $check_stmt->bindParam(':id', $data['donation_id'], PDO::PARAM_INT);
        $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Donation not found or already completed']);
            return;
        }
        
        // Update donation status
        $stmt = $conn->prepare("
            UPDATE donations
            SET status = 'completed', completed_at = NOW()
            WHERE id = :id AND user_id = :user_id
        ");
        
        $stmt->bindParam(':id', $data['donation_id'], PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation marked as completed'
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to complete donation: ' . $e->getMessage()]);
    }
}

// Function to schedule a donation without authentication
function scheduleDonationWithoutAuth() {
    global $conn;
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['center_id']) || !isset($data['scheduled_date'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Center ID and scheduled date are required']);
        return;
    }
    
    try {
        // Verify center exists
        $check_stmt = $conn->prepare("
            SELECT id FROM donation_centers
            WHERE id = :id AND status = 'active'
        ");
        $check_stmt->bindParam(':id', $data['center_id'], PDO::PARAM_INT);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Donation center not found']);
            return;
        }
        
        // For guest donations, use user_id = 0 or create a guest user
        $user_id = isset($data['guest_donation']) ? 0 : null;
        
        if ($user_id === null) {
            http_response_code(401);
            echo json_encode(['error' => 'User ID is required']);
            return;
        }
        
        // Create donation record
        $stmt = $conn->prepare("
            INSERT INTO donations (
                user_id, center_id, scheduled_date, status, notes
            ) VALUES (
                :user_id, :center_id, :scheduled_date, 'scheduled', 'Guest donation'
            )
        ");
        
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':center_id', $data['center_id'], PDO::PARAM_INT);
        $stmt->bindParam(':scheduled_date', $data['scheduled_date']);
        $stmt->execute();
        
        $donation_id = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'Donation scheduled successfully',
            'donation_id' => $donation_id
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to schedule donation: ' . $e->getMessage()]);
    }
}