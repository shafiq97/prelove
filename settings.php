<?php
// settings.php - Handle server-side logic (e.g., updating settings in database)

session_start();
require_once 'db_connect.php';

// Update Settings
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $userId = $_SESSION['user_id'];

    $darkMode = isset($_POST['dark_mode']) ? 1 : 0;
    $notifications = isset($_POST['notifications']) ? 1 : 0;
    $language = $_POST['language'] ?? 'en';
    $privacy = isset($_POST['privacy']) ? 1 : 0;

    $stmt = $conn->prepare("UPDATE users SET dark_mode=?, notifications=?, language=?, privacy=? WHERE id=?");
    $stmt->bind_param("iisii", $darkMode, $notifications, $language, $privacy, $userId);

    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Settings updated."]);
    } else {
        echo json_encode(["success" => false, "message" => "Error updating settings."]);
    }
}
?>
