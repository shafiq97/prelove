<?php
// Debug script to check API functionality

// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Log to file
ini_set('log_errors', 1);
ini_set('error_log', 'api_debug.log');

echo "<h1>API Debug Tool</h1>";

// Test database connection
echo "<h2>Testing Database Connection:</h2>";
require_once 'api/v1/config.php';

// Check if connection was successful
if (isset($conn) && $conn instanceof PDO) {
    echo "<p style='color:green'>Database connection successful!</p>";
    
    // Test items table
    try {
        $stmt = $conn->prepare("SHOW TABLES LIKE 'items'");
        $stmt->execute();
        $tableExists = $stmt->rowCount() > 0;
        
        if ($tableExists) {
            echo "<p>Items table exists.</p>";
            
            // Count records
            $stmt = $conn->prepare("SELECT COUNT(*) FROM items");
            $stmt->execute();
            $count = $stmt->fetchColumn();
            echo "<p>Items table contains {$count} records.</p>";
            
            // Check table structure
            echo "<h3>Items Table Structure:</h3>";
            $stmt = $conn->prepare("DESCRIBE items");
            $stmt->execute();
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "<pre>" . print_r($columns, true) . "</pre>";
        } else {
            echo "<p style='color:red'>Items table does not exist!</p>";
        }
    } catch (PDOException $e) {
        echo "<p style='color:red'>Error checking items table: " . $e->getMessage() . "</p>";
    }
} else {
    echo "<p style='color:red'>Database connection failed!</p>";
}

// Test API endpoint
echo "<h2>Testing API Endpoint:</h2>";

// Helper function to make API request
function makeApiRequest($url) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, true);
    
    $response = curl_exec($ch);
    $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $header = substr($response, 0, $header_size);
    $body = substr($response, $header_size);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    curl_close($ch);
    
    return [
        'code' => $http_code,
        'headers' => $header,
        'body' => $body
    ];
}

// Test the items API endpoint
$apiUrl = 'http://localhost/fypProject/api/v1/items_api.php?action=get_items&page=1';
echo "<p>Testing URL: {$apiUrl}</p>";

$result = makeApiRequest($apiUrl);

echo "<p>Response Status Code: {$result['code']}</p>";
echo "<p>Response Headers:</p>";
echo "<pre>" . htmlspecialchars($result['headers']) . "</pre>";
echo "<p>Response Body:</p>";
echo "<pre>" . htmlspecialchars($result['body']) . "</pre>";

// If there was an error, provide troubleshooting suggestions
if ($result['code'] >= 400) {
    echo "<h2>Troubleshooting Suggestions:</h2>";
    echo "<ul>";
    echo "<li>Check PHP error logs at: " . ini_get('error_log') . "</li>";
    echo "<li>Verify database credentials in api/v1/config.php</li>";
    echo "<li>Ensure 'items' table exists with correct structure</li>";
    echo "<li>Check permissions on API files and directories</li>";
    echo "</ul>";
}
?>
