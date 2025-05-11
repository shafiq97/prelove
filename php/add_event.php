<?php
include 'db_connection.php'; // ✅ Correct placement

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $title = $_POST['title'];
    $datetime = $_POST['datetime'];
    $category = $_POST['category'];
    $reminder = isset($_POST['reminder']) ? 1 : 0;

    $stmt = $conn->prepare("INSERT INTO schedule (event_title, event_date, category, reminder) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("sssi", $title, $datetime, $category, $reminder);
    $stmt->execute();

    header("Location: schedule.html");
    exit(); // 
}
?>
