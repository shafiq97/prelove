<?php
include 'db_connection.php';

header('Content-Type: application/json');

try {
    $stmt = $conn->prepare("SELECT * FROM schedule ORDER BY event_date ASC");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode($events);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
