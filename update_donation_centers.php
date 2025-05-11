<?php
require_once 'api/v1/config.php';

echo "<h1>Updating Donation Centers</h1>";

try {
    // First, check if location column exists
    $stmt = $conn->prepare("SHOW COLUMNS FROM donation_centers LIKE 'location'");
    $stmt->execute();
    $columnExists = $stmt->rowCount() > 0;
    
    if (!$columnExists) {
        echo "<p>Location column doesn't exist yet. Skipping update.</p>";
    } else {
        // Update location to match name for any centers where location is null
        $stmt = $conn->prepare("
            UPDATE donation_centers 
            SET location = name 
            WHERE location IS NULL OR location = ''
        ");
        $stmt->execute();
        $rowCount = $stmt->rowCount();
        
        echo "<p style='color:green'>Updated {$rowCount} donation centers with location = name</p>";
        
        // Show sample results
        $stmt = $conn->prepare("SELECT id, name, location FROM donation_centers LIMIT 10");
        $stmt->execute();
        $centers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "<h3>Sample Donation Centers:</h3>";
        echo "<ul>";
        foreach ($centers as $center) {
            echo "<li>ID: {$center['id']}, Name: {$center['name']}, Location: {$center['location']}</li>";
        }
        echo "</ul>";
    }
    
    echo "<p>Process completed.</p>";
    
} catch (PDOException $e) {
    echo "<p style='color:red'>Error: " . $e->getMessage() . "</p>";
}
?>
