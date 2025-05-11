<?php
require_once 'api/v1/config.php';

// Function to check if user is admin
function isAdmin() {
    // Check if user is logged in
    session_start();
    
    if (!isset($_SESSION['user']) || !isset($_SESSION['token'])) {
        return false;
    }
    
    // Verify the token
    $token = $_SESSION['token'];
    $user_data = verifyToken($token);
    
    // Check if user has admin role
    if (!$user_data || !isset($user_data['role']) || $user_data['role'] !== 'admin') {
        return false;
    }
    
    return true;
}

// Redirect if not admin
function requireAdmin() {
    if (!isAdmin()) {
        header('Location: login.html');
        exit;
    }
}
?>
