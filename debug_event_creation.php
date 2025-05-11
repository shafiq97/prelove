<?php
require_once 'api/v1/config.php';

echo "<h1>Debug Event Creation</h1>";

try {
    // Check the events table structure
    $stmt = $conn->prepare("DESCRIBE events");
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Events Table Structure:</h2>";
    echo "<table border='1'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    foreach ($columns as $col) {
        echo "<tr>";
        echo "<td>{$col['Field']}</td>";
        echo "<td>{$col['Type']}</td>";
        echo "<td>{$col['Null']}</td>";
        echo "<td>{$col['Key']}</td>";
        echo "<td>{$col['Default']}</td>";
        echo "<td>{$col['Extra']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show sample events
    $stmt = $conn->prepare("
        SELECT e.id, e.title, e.description, e.event_date, e.location, 
               e.outfit_id, e.user_id, u.username
        FROM events e
        JOIN users u ON e.user_id = u.id
        ORDER BY e.created_at DESC
        LIMIT 10
    ");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Recent Events:</h2>";
    if (count($events) > 0) {
        echo "<table border='1'>";
        echo "<tr><th>ID</th><th>Title</th><th>Description</th><th>Date</th><th>Location</th><th>Outfit ID</th><th>User</th></tr>";
        foreach ($events as $event) {
            echo "<tr>";
            echo "<td>{$event['id']}</td>";
            echo "<td>{$event['title']}</td>";
            echo "<td>{$event['description']}</td>";
            echo "<td>{$event['event_date']}</td>";
            echo "<td>" . ($event['location'] ? $event['location'] : "<span style='color:red'>NULL</span>") . "</td>";
            echo "<td>{$event['outfit_id']}</td>";
            echo "<td>{$event['username']} (ID: {$event['user_id']})</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No events found</p>";
    }
    
    // Create a test event with location
    if (isset($_GET['create_test'])) {
        $userId = 1; // Use a valid user ID from your database
        
        $stmt = $conn->prepare("
            INSERT INTO events (
                user_id, title, description, event_date, 
                location, outfit_id
            ) VALUES (
                :user_id, :title, :description, :event_date, 
                :location, :outfit_id
            )
        ");
        
        $title = "Test Event with Location";
        $description = "This is a test event created to debug location";
        $eventDate = date('Y-m-d H:i:s');
        $location = "Test Location";
        $outfitId = null;
        
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':event_date', $eventDate);
        $stmt->bindParam(':location', $location);
        $stmt->bindParam(':outfit_id', $outfitId, PDO::PARAM_INT);
        
        if ($stmt->execute()) {
            echo "<p style='color:green'>Test event created successfully!</p>";
            echo "<p>Refresh this page to see the new event in the list.</p>";
        } else {
            $errorInfo = $stmt->errorInfo();
            echo "<p style='color:red'>Error creating test event: " . $errorInfo[2] . "</p>";
        }
    } else {
        echo "<p><a href='?create_test=1'>Create a test event with location</a></p>";
    }
    
} catch (PDOException $e) {
    echo "<p style='color:red'>Database Error: " . $e->getMessage() . "</p>";
} catch (Exception $e) {
    echo "<p style='color:red'>Error: " . $e->getMessage() . "</p>";
}
?>
