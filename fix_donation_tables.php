<?php
require_once 'api/v1/config.php';

echo "<h1>Updating Donation Tables</h1>";

try {
    // Check if scheduled_date is DATE type
    $stmt = $conn->prepare("SHOW COLUMNS FROM donations WHERE Field = 'scheduled_date'");
    $stmt->execute();
    $column = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<p>Current scheduled_date type: " . $column['Type'] . "</p>";
    
    // Alter the column to DATETIME if it's not already
    if (strpos(strtolower($column['Type']), 'datetime') === false) {
        $stmt = $conn->prepare("ALTER TABLE donations MODIFY COLUMN scheduled_date DATETIME NOT NULL");
        $stmt->execute();
        echo "<p style='color:green'>Successfully updated scheduled_date column to DATETIME</p>";
    } else {
        echo "<p>scheduled_date is already DATETIME type. No change needed.</p>";
    }
    
    // Fix existing data with empty time values
    $stmt = $conn->prepare("
        UPDATE donations 
        SET scheduled_date = CONCAT(scheduled_date, ' 12:00:00')
        WHERE TIME(scheduled_date) = '00:00:00'
    ");
    $stmt->execute();
    $rowCount = $stmt->rowCount();
    echo "<p style='color:green'>Updated {$rowCount} records with default time (12:00:00) for entries with 00:00:00 time</p>";
    
    echo "<p>Update completed successfully!</p>";
    
    // Show some sample donations to verify
    $stmt = $conn->prepare("SELECT id, scheduled_date FROM donations LIMIT 10");
    $stmt->execute();
    $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h3>Sample Donation Records:</h3>";
    echo "<ul>";
    foreach ($samples as $sample) {
        echo "<li>ID: {$sample['id']}, Scheduled Date: {$sample['scheduled_date']}</li>";
    }
    echo "</ul>";
    
} catch (PDOException $e) {
    echo "<p style='color:red'>Error: " . $e->getMessage() . "</p>";
}
?>
