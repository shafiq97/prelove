<?php
// Database schema validation and correction script
require_once '/Applications/XAMPP/xamppfiles/htdocs/fypProject/api/v1/config.php';

echo "<h1>Database Schema Validator</h1>";

// Check if items table has the correct columns
function checkAndUpdateItemsTable($conn) {
    echo "<h2>Checking Items Table</h2>";
    
    try {
        // First check if the items table exists
        $stmt = $conn->prepare("SHOW TABLES LIKE 'items'");
        $stmt->execute();
        $tableExists = $stmt->rowCount() > 0;
        
        if (!$tableExists) {
            echo "<p style='color:red'>Items table does not exist! Creating it now...</p>";
            
            // Create the table
            $createTableSQL = "
                CREATE TABLE items (
                    id INT PRIMARY KEY AUTO_INCREMENT,
                    name VARCHAR(100) NOT NULL,
                    description TEXT,
                    price DECIMAL(10,2) NOT NULL,
                    category VARCHAR(50) NOT NULL,
                    size VARCHAR(20) DEFAULT 'One Size',
                    color VARCHAR(30) DEFAULT 'Not specified',
                    brand VARCHAR(50) DEFAULT 'Unbranded',
                    image_url VARCHAR(255),
                    `condition` VARCHAR(50) NOT NULL,
                    seller_id INT NOT NULL,
                    seller_name VARCHAR(100) NOT NULL,
                    is_available BOOLEAN DEFAULT true,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            ";
            
            $conn->exec($createTableSQL);
            echo "<p style='color:green'>Items table created successfully!</p>";
            return;
        }
        
        echo "<p style='color:green'>Items table exists</p>";
        
        // Now check the columns
        $stmt = $conn->prepare("DESCRIBE items");
        $stmt->execute();
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        echo "<p>Existing columns: " . implode(", ", $columns) . "</p>";
        
        // Expected columns
        $expectedColumns = [
            'id', 'name', 'description', 'price', 'category', 'size', 'color', 'brand',
            'image_url', 'condition', 'seller_id', 'seller_name', 'is_available', 
            'created_at', 'updated_at'
        ];
        
        $missingColumns = array_diff($expectedColumns, $columns);
        
        if (!empty($missingColumns)) {
            echo "<p style='color:orange'>Missing columns: " . implode(", ", $missingColumns) . "</p>";
            
            // Add missing columns
            foreach ($missingColumns as $column) {
                $alterSQL = "";
                
                switch ($column) {
                    case 'size':
                        $alterSQL = "ALTER TABLE items ADD COLUMN size VARCHAR(20) DEFAULT 'One Size' AFTER category";
                        break;
                    case 'color':
                        $alterSQL = "ALTER TABLE items ADD COLUMN color VARCHAR(30) DEFAULT 'Not specified' AFTER size";
                        break;
                    case 'brand':
                        $alterSQL = "ALTER TABLE items ADD COLUMN brand VARCHAR(50) DEFAULT 'Unbranded' AFTER color";
                        break;
                    case 'seller_id':
                        $alterSQL = "ALTER TABLE items ADD COLUMN seller_id INT NOT NULL AFTER `condition`";
                        break;
                    case 'seller_name':
                        $alterSQL = "ALTER TABLE items ADD COLUMN seller_name VARCHAR(100) NOT NULL AFTER seller_id";
                        break;
                    // Add more cases for other columns as needed
                }
                
                if (!empty($alterSQL)) {
                    try {
                        $conn->exec($alterSQL);
                        echo "<p style='color:green'>Added column '$column' successfully</p>";
                    } catch (PDOException $e) {
                        echo "<p style='color:red'>Failed to add column '$column': " . $e->getMessage() . "</p>";
                    }
                }
            }
        } else {
            echo "<p style='color:green'>All required columns exist!</p>";
        }
        
        // Check if condition_type exists instead of condition
        if (in_array('condition_type', $columns) && !in_array('condition', $columns)) {
            echo "<p style='color:orange'>Found 'condition_type' column but 'condition' is missing. Renaming column...</p>";
            try {
                $conn->exec("ALTER TABLE items CHANGE condition_type `condition` VARCHAR(50) NOT NULL");
                echo "<p style='color:green'>Renamed 'condition_type' to 'condition' successfully</p>";
            } catch (PDOException $e) {
                echo "<p style='color:red'>Failed to rename column: " . $e->getMessage() . "</p>";
            }
        }
        
        // Check if user_id exists instead of seller_id
        if (in_array('user_id', $columns) && !in_array('seller_id', $columns)) {
            echo "<p style='color:orange'>Found 'user_id' column. Creating alias to 'seller_id'...</p>";
            try {
                $conn->exec("ALTER TABLE items CHANGE user_id seller_id INT NOT NULL");
                echo "<p style='color:green'>Renamed 'user_id' to 'seller_id' successfully</p>";
            } catch (PDOException $e) {
                echo "<p style='color:red'>Failed to rename column: " . $e->getMessage() . "</p>";
            }
        }
        
    } catch (PDOException $e) {
        echo "<p style='color:red'>Database error: " . $e->getMessage() . "</p>";
    }
}

// Run the checks and fixes
if (isset($conn) && $conn instanceof PDO) {
    checkAndUpdateItemsTable($conn);
} else {
    echo "<p style='color:red'>No database connection available!</p>";
}

// Verify uploads directory
echo "<h2>Checking Uploads Directory</h2>";
$uploadsDir = '/Applications/XAMPP/xamppfiles/htdocs/fypProject/uploads';

if (!file_exists($uploadsDir)) {
    echo "<p style='color:orange'>Uploads directory does not exist. Creating...</p>";
    if (mkdir($uploadsDir, 0777, true)) {
        echo "<p style='color:green'>Uploads directory created successfully.</p>";
    } else {
        echo "<p style='color:red'>Failed to create uploads directory!</p>";
    }
} else {
    echo "<p style='color:green'>Uploads directory exists.</p>";
    
    // Check permissions
    if (is_writable($uploadsDir)) {
        echo "<p style='color:green'>Uploads directory is writable.</p>";
    } else {
        echo "<p style='color:red'>Uploads directory is not writable! Fixing permissions...</p>";
        if (chmod($uploadsDir, 0777)) {
            echo "<p style='color:green'>Fixed uploads directory permissions.</p>";
        } else {
            echo "<p style='color:red'>Failed to fix permissions. Please set manually.</p>";
        }
    }
}

// Add a button to return to API diagnostic
echo '<p><a href="/fypProject/api_diagnostic.php" style="padding: 10px; background-color: #3498db; color: white; text-decoration: none; border-radius: 5px;">Back to API Diagnostic</a></p>';

?>
