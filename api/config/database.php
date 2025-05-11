<?php
// Database connection parameters
$host = 'localhost';
$db_name = 'prelove_db';
$username = 'root'; // Default XAMPP username
$password = ''; // Default XAMPP password (empty)

// Create connection
$conn = new mysqli($host, $username, $password, $db_name);

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        'success' => false,
        'error' => 'Database connection failed: ' . $conn->connect_error
    ]));
}
?>