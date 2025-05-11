<?php
// Debug script to check planner_api.php endpoint
require_once 'api/v1/headers.php';
require_once 'api/v1/config.php';

// Test token
$token = isset($_GET['token']) 
    ? $_GET['token'] 
    : 'eyJ1c2VyX2lkIjozLCJ1c2VybmFtZSI6ImFiYyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';

echo "<h1>Planner API Debug</h1>";
echo "<pre>";

// First check PHP syntax
echo "CHECKING PHP SYNTAX\n";
echo "===================\n\n";
$filename = 'api/v1/planner_api.php';
$output = [];
$return_var = 0;
exec("php -l $filename 2>&1", $output, $return_var);
echo implode("\n", $output) . "\n\n";

// Now test create_outfit endpoint
echo "TESTING CREATE_OUTFIT ENDPOINT\n";
echo "=============================\n\n";
$url = 'http://localhost/fypProject/api/v1/planner_api.php?action=create_outfit';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_VERBOSE, true);

// Create an empty request body
$requestData = json_encode([
    'name' => 'Debug Test Outfit',
    'description' => 'Created for testing'
]);

// Set headers
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json', 
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestData);

// Log request
echo "Request URL: $url\n";
echo "Request Headers: Authorization: Bearer " . substr($token, 0, 20) . "...\n";
echo "Request Body: $requestData\n\n";

// Execute request
$response = curl_exec($ch);
$info = curl_getinfo($ch);
curl_close($ch);

// Output response
echo "Response Status: " . $info['http_code'] . "\n";
echo "Response Body:\n" . ($response ?: "Empty response") . "\n\n";

// If there was an error, try to output PHP error logs
echo "PHP ERROR LOGS\n";
echo "=============\n\n";

// Try to fetch from common PHP error log locations
$possibleLogFiles = [
    '/Applications/XAMPP/xamppfiles/logs/php_error_log',
    '/Applications/XAMPP/xamppfiles/logs/error_log',
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/logs/php_error.log',
    '/Applications/XAMPP/xamppfiles/htdocs/fypProject/logs/error_log'
];

$logFound = false;
foreach ($possibleLogFiles as $logFile) {
    if (file_exists($logFile)) {
        echo "From $logFile (last 10 lines):\n";
        passthru("tail -n 10 $logFile");
        echo "\n\n";
        $logFound = true;
    }
}

if (!$logFound) {
    echo "No PHP error logs found in common locations.\n";
}

// Now let's examine planner_api.php file to look for issues
echo "EXAMINING planner_api.php createOutfit FUNCTION\n";
echo "============================================\n\n";

$fileContent = file_get_contents('api/v1/planner_api.php');
if ($fileContent) {
    // Try to find the createOutfit function
    if (preg_match('/function\s+createOutfit.*?\{.*?\}/s', $fileContent, $matches)) {
        echo "Found createOutfit function:\n";
        echo htmlspecialchars($matches[0]) . "\n\n";
    } else {
        echo "Couldn't find createOutfit function in the file.\n";
    }
} else {
    echo "Could not read planner_api.php file.\n";
}

echo "</pre>";
?>
