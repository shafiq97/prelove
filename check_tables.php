<?php
// Database connection
include_once 'db_connection.php';

// Check donations table structure
$query = "DESCRIBE donations";
$result = $conn->query($query);

echo "<h2>Donations Table Structure</h2>";
echo "<pre>";
while ($row = $result->fetch_assoc()) {
    print_r($row);
}
echo "</pre>";

// Check donation_centers table structure
$query = "DESCRIBE donation_centers";
$result = $conn->query($query);

echo "<h2>Donation Centers Table Structure</h2>";
echo "<pre>";
while ($row = $result->fetch_assoc()) {
    print_r($row);
}
echo "</pre>";
?>
