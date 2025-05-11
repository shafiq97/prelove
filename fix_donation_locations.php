<?php
// Database connection
include_once 'db_connection.php';

// Add location information to the results when querying donations
$sql = "
    UPDATE donation_centers 
    SET location = CONCAT(name, ' (', address, ')')
    WHERE location IS NULL OR location = '';
";

$result = $conn->query($sql);

if ($result) {
    echo "Successfully updated donation center locations.<br>";
    echo "Updated " . $conn->affected_rows . " rows.";
} else {
    echo "Error updating location data: " . $conn->error;
}
?>
