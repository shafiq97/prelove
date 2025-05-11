<?php
// Test script for creating an outfit via API
header('Content-Type: application/json');

// API endpoint
$url = 'http://localhost/fypProject/api/v1/planner_api.php?action=create_outfit';

// Test token
$token = isset($_GET['token']) 
    ? $_GET['token'] 
    : 'eyJ1c2VyX2lkIjozLCJ1c2VybmFtZSI6ImFiYyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';

// Request data
$data = [
    'name' => 'Test Outfit ' . date('Y-m-d H:i:s'),
    'description' => 'Created via test script',
    'items' => []
];

// Initialize curl
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);

// Execute request
$response = curl_exec($ch);
$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// Return response
echo json_encode([
    'status' => $status,
    'response' => json_decode($response, true) ?? $response
]);
?>
