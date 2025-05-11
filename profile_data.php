<?php
// profile_data.php

session_start();

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit();
}

$user_id = $_SESSION['user_id'];

// Include database connection
include 'db_connection.php';

// Fetch User Info with Profile Picture & Join Date
$user_query = $conn->prepare("SELECT username, email, profile_picture, join_date FROM users WHERE id = ?");
$user_query->bind_param("i", $user_id);
$user_query->execute();
$user_result = $user_query->get_result();
$user = $user_result->fetch_assoc();

// Fetch Items for Sale
$sell_query = $conn->prepare("SELECT name, price, image FROM items WHERE user_id = ? AND type = 'sell'");
sell_query->bind_param("i", $user_id);
sell_query->execute();
sell_items = $sell_query->get_result()->fetch_all(MYSQLI_ASSOC);

// Fetch Donated Items
$donate_query = $conn->prepare("SELECT name, donated_date FROM items WHERE user_id = ? AND type = 'donate'");
donate_query->bind_param("i", $user_id);
donate_query->execute();
donate_items = $donate_query->get_result()->fetch_all(MYSQLI_ASSOC);

// Fetch Cart Items (Only Active Purchases)
$cart_query = $conn->prepare("SELECT name, price, status FROM cart WHERE user_id = ? AND status = 'pending'");
$cart_query->bind_param("i", $user_id);
$cart_query->execute();
$cart_items = $cart_query->get_result()->fetch_all(MYSQLI_ASSOC);

header('Content-Type: application/json');

echo json_encode([
    'user' => $user,
    'sell_items' => $sell_items,
    'donate_items' => $donate_items,
    'cart_items' => $cart_items
]);

$conn->close();
?>
