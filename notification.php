<?php
// notification.php - Fetch notifications

include 'db_connection.php'; // ✅ Use external connection file

$sql = "SELECT type, message, created_at FROM notifications ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->execute();
$result = $stmt->get_result();

$notifications = [];
while ($row = $result->fetch_assoc()) {
    $notifications[] = $row;
}

header('Content-Type: application/json');
echo json_encode($notifications);

$conn->close();
?>
