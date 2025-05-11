<?php
require_once 'config.php';

try {
    // Check donations table structure
    $stmt = $conn->prepare("DESCRIBE donations");
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Donations Table Structure</h2>";
    echo "<pre>";
    print_r($columns);
    echo "</pre>";
    
    // Check donation_centers table structure
    $stmt = $conn->prepare("DESCRIBE donation_centers");
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Donation Centers Table Structure</h2>";
    echo "<pre>";
    print_r($columns);
    echo "</pre>";
    
    // Sample data
    $stmt = $conn->prepare("SELECT * FROM donations LIMIT 5");
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Sample Donations Data</h2>";
    echo "<pre>";
    print_r($data);
    echo "</pre>";
    
    // Sample centers
    $stmt = $conn->prepare("SELECT * FROM donation_centers LIMIT 5");
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h2>Sample Donation Centers Data</h2>";
    echo "<pre>";
    print_r($data);
    echo "</pre>";
    
} catch (PDOException $e) {
    echo "<h1>Error</h1>";
    echo "<p>" . $e->getMessage() . "</p>";
}
?>
