<?php
// This script checks and verifies the PHP configuration and server setup 
header('Content-Type: text/html; charset=UTF-8');

echo "<html><head><title>API Diagnostic Tool</title>";
echo "<style>
body { font-family: Arial, sans-serif; margin: 20px; }
h1 { color: #2c3e50; }
h2 { color: #3498db; margin-top: 20px; }
.section { border: 1px solid #ddd; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
.success { color: green; }
.warning { color: orange; }
.error { color: red; }
pre { background-color: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
table { border-collapse: collapse; width: 100%; }
table, th, td { border: 1px solid #ddd; }
th, td { padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
</style>";
echo "</head><body>";

echo "<h1>API Diagnostic Tool</h1>";

// PHP Version and extensions
echo "<div class='section'>";
echo "<h2>PHP Environment</h2>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";

$required_extensions = ['pdo', 'pdo_mysql', 'json', 'curl', 'fileinfo'];
echo "<p><strong>Required Extensions:</strong></p>";
echo "<ul>";
foreach ($required_extensions as $ext) {
    $loaded = extension_loaded($ext);
    $status_class = $loaded ? 'success' : 'error';
    echo "<li class='$status_class'>" . $ext . ": " . ($loaded ? "Loaded" : "Not Loaded") . "</li>";
}
echo "</ul>";

echo "<p><strong>PHP Configuration:</strong></p>";
echo "<ul>";
$memory_limit = ini_get('memory_limit');
$upload_max_filesize = ini_get('upload_max_filesize');
$post_max_size = ini_get('post_max_size');
echo "<li>memory_limit: $memory_limit</li>";
echo "<li>upload_max_filesize: $upload_max_filesize</li>";
echo "<li>post_max_size: $post_max_size</li>";
echo "</ul>";
echo "</div>";

// Directory Structure and Permissions
echo "<div class='section'>";
echo "<h2>Directory Structure and Permissions</h2>";

$paths_to_check = [
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/api',
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/api/v1',
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/logs',
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/uploads'
];

echo "<table>";
echo "<tr><th>Path</th><th>Exists</th><th>Readable</th><th>Writable</th><th>Permissions</th></tr>";

foreach ($paths_to_check as $path) {
    $exists = file_exists($path);
    $readable = is_readable($path);
    $writable = is_writable($path);
    $perms = $exists ? substr(sprintf('%o', fileperms($path)), -4) : 'N/A';
    
    $exists_class = $exists ? 'success' : 'error';
    $readable_class = $readable ? 'success' : 'error';
    $writable_class = $writable ? 'success' : 'error';
    
    echo "<tr>";
    echo "<td>$path</td>";
    echo "<td class='$exists_class'>" . ($exists ? "Yes" : "No") . "</td>";
    echo "<td class='$readable_class'>" . ($readable ? "Yes" : "No") . "</td>";
    echo "<td class='$writable_class'>" . ($writable ? "Yes" : "No") . "</td>";
    echo "<td>$perms</td>";
    echo "</tr>";
}
echo "</table>";

echo "</div>";

// Database Connection Test
echo "<div class='section'>";
echo "<h2>Database Connection Test</h2>";

require_once '/Applications/XAMPP/xamppfiles/htdocs/fypProject/api/v1/config.php';

// First, verify that the config.php is correctly brought in
if (!isset($host) || !isset($dbname) || !isset($username)) {
    echo "<p class='error'>Failed to load database configuration variables from config.php</p>";
} else {
    echo "<p>Database Configuration:</p>";
    echo "<ul>";
    echo "<li>Host: " . $host . "</li>";
    echo "<li>Database: " . $dbname . "</li>";
    echo "<li>Username: " . $username . "</li>";
    echo "</ul>";
    
    // Check if we can connect to the database
    if (isset($conn) && $conn instanceof PDO) {
        echo "<p class='success'>Successfully connected to the database!</p>";
        
        // Test the items table
        try {
            $stmt = $conn->prepare("SHOW TABLES LIKE 'items'");
            $stmt->execute();
            $items_table_exists = $stmt->rowCount() > 0;
            
            if ($items_table_exists) {
                echo "<p class='success'>Items table exists!</p>";
                
                // Get item count
                $stmt = $conn->prepare("SELECT COUNT(*) FROM items");
                $stmt->execute();
                $item_count = $stmt->fetchColumn();
                echo "<p>Items table contains <strong>$item_count</strong> records.</p>";
                
                // Verify table structure
                $stmt = $conn->prepare("DESCRIBE items");
                $stmt->execute();
                $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
                
                echo "<p>Items table structure:</p>";
                echo "<ul>";
                foreach ($columns as $column) {
                    echo "<li>" . htmlspecialchars($column) . "</li>";
                }
                echo "</ul>";
                
                // Get a sample item to verify data
                if ($item_count > 0) {
                    $stmt = $conn->prepare("SELECT * FROM items LIMIT 1");
                    $stmt->execute();
                    $sample_item = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    echo "<p>Sample item:</p>";
                    echo "<pre>" . json_encode($sample_item, JSON_PRETTY_PRINT) . "</pre>";
                }
            } else {
                echo "<p class='error'>Items table does not exist!</p>";
            }
        } catch (PDOException $e) {
            echo "<p class='error'>Error testing database: " . $e->getMessage() . "</p>";
        }
    } else {
        echo "<p class='error'>Failed to connect to the database!</p>";
    }
}
echo "</div>";

// API Endpoint Test
echo "<div class='section'>";
echo "<h2>API Endpoint Test</h2>";

function testEndpoint($url, $method = 'GET', $data = null) {
    echo "<h3>Testing: $url</h3>";
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    
    if ($method == 'POST') {
        curl_setopt($ch, CURLOPT_POST, 1);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    }
    
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    
    echo "<p>HTTP Status Code: <strong>$httpCode</strong></p>";
    
    if ($error) {
        echo "<p class='error'>CURL Error: $error</p>";
    }
    
    echo "<p>Response:</p>";
    echo "<pre>";
    if ($response) {
        // Try to pretty print if it's JSON
        $decoded = json_decode($response, true);
        if ($decoded) {
            echo json_encode($decoded, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        } else {
            // Not valid JSON, just output as is
            echo htmlspecialchars($response);
        }
    } else {
        echo "No response or empty response";
    }
    echo "</pre>";
    
    curl_close($ch);
}

// Test the items_api.php endpoint
testEndpoint('http://localhost/fypProject/api/v1/items_api.php?action=get_items&page=1');

echo "</div>";

// Error Log
echo "<div class='section'>";
echo "<h2>PHP Error Log</h2>";

$error_log_path = '/Applications/XAMPP/xamppfiles/htdocs/fypProject/logs/api_error.log';

if (file_exists($error_log_path)) {
    if (is_readable($error_log_path)) {
        $log_contents = file_get_contents($error_log_path);
        if (empty($log_contents)) {
            echo "<p>Error log is empty. No errors have been recorded.</p>";
        } else {
            // Get the last 20 lines of the log
            $log_lines = explode("\n", $log_contents);
            $last_lines = array_slice($log_lines, -20);
            
            echo "<p>Last 20 log entries:</p>";
            echo "<pre>";
            foreach ($last_lines as $line) {
                echo htmlspecialchars($line) . "\n";
            }
            echo "</pre>";
        }
    } else {
        echo "<p class='error'>Error log exists but is not readable.</p>";
    }
} else {
    echo "<p class='warning'>Error log does not exist at $error_log_path</p>";
    
    // Check if we can create it
    $log_dir = dirname($error_log_path);
    if (is_writable($log_dir)) {
        echo "<p>The directory is writable, so the log file should be created when errors occur.</p>";
    } else {
        echo "<p class='error'>The directory $log_dir is not writable. PHP may not be able to create error logs.</p>";
    }
}

echo "</div>";

// Recommendations
echo "<div class='section'>";
echo "<h2>Recommendations</h2>";
echo "<ul>";
echo "<li>Make sure all required PHP extensions are installed.</li>";
echo "<li>Ensure the logs directory is writable by the web server.</li>";
echo "<li>Check that your database connection parameters are correct in config.php.</li>";
echo "<li>If you're using Android emulator, ensure 10.0.2.2 is used as host in your Flutter app to connect to localhost.</li>";
echo "<li>Verify your API endpoints are accessible and returning proper JSON responses.</li>";
echo "<li>Check CORS headers if you're experiencing cross-origin issues.</li>";
echo "</ul>";
echo "</div>";

echo "</body></html>";
