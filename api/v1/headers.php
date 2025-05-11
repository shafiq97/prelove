<?php
// Allow requests from the Flutter app on Android emulator
header("Access-Control-Allow-Origin: *");

// Allow specific HTTP methods
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

// Allow specific headers including Authorization
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// Max age for preflight cache (1 hour)
header("Access-Control-Max-Age: 3600");

// Content type
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    error_log("Handling OPTIONS preflight request");
    exit;
}
?>