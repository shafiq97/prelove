<?php
// Run database updates for donations and donation centers

// Database connection
require_once 'db_connection.php';

// Display errors for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h1>Updating Donation Tables</h1>";

try {
    // Load SQL file
    $sql = file_get_contents('database/update_donation_tables.sql');
    
    // Split into individual statements
    $statements = explode(';', $sql);
    
    // Execute each statement
    foreach ($statements as $statement) {
        $statement = trim($statement);
        if (!empty($statement)) {
            $conn->exec($statement);
            echo "<div style='color:green'>Executed: " . htmlspecialchars($statement) . "</div><br>";
        }
    }
    
    echo "<h2>Database updated successfully!</h2>";
    
    // Check if columns were added
    $checkLocationCol = $conn->query("SHOW COLUMNS FROM donation_centers LIKE 'location'");
    $hasLocationCol = $checkLocationCol->rowCount() > 0;
    
    $checkDatetimeCol = $conn->query("SHOW COLUMNS FROM donations WHERE Field = 'scheduled_date' AND Type LIKE '%datetime%'");
    $hasDatetimeCol = $checkDatetimeCol->rowCount() > 0;
    
    echo "<h3>Verification Results:</h3>";
    echo "<ul>";
    echo "<li>'location' column added to donation_centers: " . ($hasLocationCol ? "Yes ✓" : "No ✗") . "</li>";
    echo "<li>'scheduled_date' converted to DATETIME: " . ($hasDatetimeCol ? "Yes ✓" : "No ✗") . "</li>";
    echo "</ul>";
    
} catch (PDOException $e) {
    echo "<div style='color:red'>Database Error: " . $e->getMessage() . "</div>";
}
?>
