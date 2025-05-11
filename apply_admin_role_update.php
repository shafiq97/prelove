<?php
// Apply the database update for admin roles
require_once 'api/v1/config.php';

try {
    global $conn;
    
    // Get the SQL file content
    $sql_file = file_get_contents('database/update_admin_role.sql');
    
    if (!$sql_file) {
        die("Could not read the SQL file.");
    }
    
    // Split SQL file into individual statements
    $statements = explode(';', $sql_file);
    
    // Execute each statement
    foreach ($statements as $statement) {
        $statement = trim($statement);
        if (!empty($statement)) {
            echo "Executing: " . substr($statement, 0, 50) . "...\n";
            $conn->exec($statement);
        }
    }
    
    echo "Database update for admin roles applied successfully.\n";
    echo "Added 'role' column to users table.\n";
    echo "Set up admin user with username 'admin' and password 'admin123'.\n";
    
} catch (PDOException $e) {
    die("Database error: " . $e->getMessage());
}
?>
