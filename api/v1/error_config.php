<?php
// Error configuration for API
ini_set('display_errors', 1); // Enable for debugging
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Set up error logging
ini_set('log_errors', 1);
$log_dir = __DIR__ . '/../../logs';

// Ensure the logs directory exists
if (!file_exists($log_dir)) {
    mkdir($log_dir, 0775, true);
}

ini_set('error_log', $log_dir . '/api_error.log');

// Log a message to confirm this file was loaded
error_log('Error configuration loaded from error_config.php');
