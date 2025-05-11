<?php
// Enable error reporting
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Log errors to a file
ini_set('log_errors', 1);
ini_set('error_log', '/Applications/XAMPP/xamppfiles/logs/planner_debug.log');

// Test the planner_api.php endpoint
echo "<h1>Debugging Planner API</h1>";

// Include the API file
require_once 'api/v1/planner_api.php';

// You can also make a direct test call to the get_outfit function
$_GET['action'] = 'get_outfit';
$_GET['outfit_id'] = 1;

// Create a mock request
$_SERVER['REQUEST_METHOD'] = 'GET';

// Execute the API request
// This would happen automatically when including the file, 
// but we can also test specific functions here
?>
