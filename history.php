<?php
include 'db_connection.php'; // ✅ Connect to database

// Query to fetch transaction history
$query = "SELECT title, date, status, category, image FROM history ORDER BY date DESC";
$result = $conn->query($query);

$history = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $history[] = $row;
    }
}

// Return JSON response
header('Content-Type: application/json');
echo json_encode($history);
?>
