<?php
// Simple test script for planner_api.php
$url = 'http://localhost/fypProject/api/v1/planner_api.php?action=get_outfit&outfit_id=1';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);

// Set authorization header if needed
$token = 'eyJ1c2VyX2lkIjozLCJ1c2VybmFtZSI6ImFiYyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
$info = curl_getinfo($ch);
curl_close($ch);

echo "Status code: " . $info['http_code'] . "\n";
echo "Response:\n";
echo $response;
?>
