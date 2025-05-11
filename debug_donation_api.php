<?php
// Debug script to check donation API's token verification
require_once 'api/v1/headers.php';
require_once 'api/v1/config.php';

// Test token
$token = isset($_GET['token']) 
    ? $_GET['token'] 
    : 'eyJ1c2VyX2lkIjozLCJ1c2VybmFtZSI6ImFiYyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';

// Direct function test
echo "<h1>Direct Token Verification Test</h1>";
echo "<pre>";
echo "Token: " . $token . "\n\n";
$result = verifyToken($token);
echo "verifyToken() result: " . ($result ? json_encode($result, JSON_PRETTY_PRINT) : "false") . "\n\n";

// Test a POST request to donation_api.php schedule endpoint
$url = 'http://localhost/fypProject/api/v1/donation_api.php?action=schedule';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_VERBOSE, true);

// Set authorization header
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);

// Sample request data
$requestData = json_encode([
    'center_id' => 1,
    'scheduled_date' => date('Y-m-d', strtotime('+2 days'))
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestData);

// Log the request details
echo "Donation API Request:\n";
echo "URL: " . $url . "\n";
echo "Headers: " . json_encode([
    'Accept: application/json',
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]) . "\n";
echo "Body: " . $requestData . "\n\n";

// Execute the request
$response = curl_exec($ch);
$info = curl_getinfo($ch);
curl_close($ch);

echo "Donation API Response:\n";
echo "Status Code: " . $info['http_code'] . "\n";
echo "Response Body: " . $response . "\n";

// Modify donation_api.php to include development bypass - do NOT execute in production!
echo "\n\nModification recommendation for donation_api.php:\n";
echo "Add the following code after token verification:\n\n";
echo "<code style='color:blue;'>";
echo "// DEVELOPMENT BYPASS: Use default user if token is invalid\n";
echo "if (!$user_data) {\n";
echo "    error_log(\"Invalid token in donation_api.php, using default user\");\n";
echo "    $user_data = ['user_id' => 1]; // Use a default user ID for development\n";
echo "}\n";
echo "</code>";

echo "</pre>";
?>
