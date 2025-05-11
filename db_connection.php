<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = "localhost";
$user = "root";
$password = "";
$database = "prelove_db";

// Create connection with charset specification
$mysqli = new mysqli($host, $user, $password, $database);

// Set charset to utf8mb4
if (!$mysqli->set_charset("utf8mb4")) {
    error_log("Error loading character set utf8mb4: " . $mysqli->error);
}

// Check connection with detailed error logging
if ($mysqli->connect_error) {
    error_log("Connection failed: " . $mysqli->connect_error);
    die(json_encode([
        'success' => false,
        'error' => 'Database connection failed'
    ]));
}

// Log successful connection
error_log("Database connected successfully");
?>
