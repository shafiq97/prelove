<?php
// Debug script to check order history API response
require_once 'api/v1/headers.php';
require_once 'api/v1/config.php';

// Try to get a token from the query string
$token = isset($_GET['token']) ? $_GET['token'] : 'eyJ1c2VyX2lkIjozLCJ1c2VybmFtZSI6ImFiYyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';

// Make a request to the cart_api.php endpoint
$url = 'http://localhost/fypProject/api/v1/cart_api.php?action=order_history';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);

// Set authorization header
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
$info = curl_getinfo($ch);
curl_close($ch);

echo "<h1>Debug Order History API Response</h1>";
echo "<pre>";
echo "Status code: " . $info['http_code'] . "\n\n";
echo "Response:\n";
echo htmlspecialchars($response);

// Decode JSON response for deeper analysis
$jsonResponse = json_decode($response, true);
if ($jsonResponse && isset($jsonResponse['history']) && is_array($jsonResponse['history'])) {
    echo "\n\nDetailed Analysis of 'amount' fields:\n";
    foreach ($jsonResponse['history'] as $index => $item) {
        if (isset($item['amount'])) {
            echo "Item $index amount: " . $item['amount'] . " (Type: " . gettype($item['amount']) . ")\n";
        }
    }
}
echo "</pre>";
?>
