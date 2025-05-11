<?php
// Test script for file uploads

// Enable verbose error reporting
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Define upload directory
$upload_dir = __DIR__ . '/uploads/';
echo "<h2>Upload Directory Test</h2>";
echo "Upload directory path: " . $upload_dir . "<br>";
echo "Directory exists: " . (is_dir($upload_dir) ? 'Yes' : 'No') . "<br>";
echo "Directory writable: " . (is_writable($upload_dir) ? 'Yes' : 'No') . "<br>";

if (!is_dir($upload_dir)) {
    echo "Creating directory...<br>";
    if (mkdir($upload_dir, 0777, true)) {
        echo "Directory created successfully.<br>";
    } else {
        echo "Failed to create directory!<br>";
    }
}

// Test file creation
echo "<h2>File Creation Test</h2>";
$test_file = $upload_dir . 'test_' . time() . '.txt';
echo "Attempting to create test file: " . $test_file . "<br>";

if (file_put_contents($test_file, 'Test content')) {
    echo "Test file created successfully.<br>";
    echo "File exists: " . (file_exists($test_file) ? 'Yes' : 'No') . "<br>";
    echo "File readable: " . (is_readable($test_file) ? 'Yes' : 'No') . "<br>";
    echo "File content: " . file_get_contents($test_file) . "<br>";
    
    // Try to delete the test file
    if (unlink($test_file)) {
        echo "Test file deleted successfully.<br>";
    } else {
        echo "Failed to delete test file.<br>";
    }
} else {
    echo "Failed to create test file!<br>";
}

// Test file upload process
echo "<h2>File Upload Form</h2>";
echo "Use this form to test file uploads:<br>";
?>

<form action="test_upload_process.php" method="post" enctype="multipart/form-data">
    <input type="file" name="test_image">
    <button type="submit">Test Upload</button>
</form>

<h2>Item Creation Form</h2>
<p>This simulates the API call from your Flutter app:</p>

<form action="api/v1/items_api.php?action=create_item" method="post" enctype="multipart/form-data">
    <div>
        <label for="name">Name:</label>
        <input type="text" name="name" value="Test Item" required>
    </div>
    <div>
        <label for="description">Description:</label>
        <textarea name="description" required>This is a test item description</textarea>
    </div>
    <div>
        <label for="price">Price:</label>
        <input type="number" name="price" value="99.99" step="0.01" required>
    </div>
    <div>
        <label for="category">Category:</label>
        <input type="text" name="category" value="Test Category" required>
    </div>
    <div>
        <label for="condition">Condition:</label>
        <input type="text" name="condition" value="Excellent" required>
    </div>
    <div>
        <label for="size">Size:</label>
        <input type="text" name="size" value="Medium">
    </div>
    <div>
        <label for="color">Color:</label>
        <input type="text" name="color" value="Blue">
    </div>
    <div>
        <label for="brand">Brand:</label>
        <input type="text" name="brand" value="Test Brand">
    </div>
    <div>
        <label for="image">Image:</label>
        <input type="file" name="image">
    </div>
    <div>
        <button type="submit">Test Create Item</button>
    </div>
</form>

<h2>API Test Links</h2>
<ul>
    <li><a href="api/v1/items_api.php?action=get_items&page=1" target="_blank">Get Items</a></li>
    <li><a href="api_diagnostic.php" target="_blank">API Diagnostic Tool</a></li>
    <li><a href="fix_database.php" target="_blank">Fix Database Schema</a></li>
</ul>
