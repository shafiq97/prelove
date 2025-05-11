<?php
// Process file upload test

// Enable verbose error reporting
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h1>Upload Test Results</h1>";

// Check if a file was uploaded
if (isset($_FILES['test_image']) && $_FILES['test_image']['error'] === UPLOAD_ERR_OK) {
    echo "<h2>File Details</h2>";
    echo "<pre>";
    print_r($_FILES['test_image']);
    echo "</pre>";
    
    // Verify upload directory
    $upload_dir = __DIR__ . '/uploads/';
    
    if (!is_dir($upload_dir)) {
        if (!mkdir($upload_dir, 0777, true)) {
            die("<p style='color:red'>Failed to create upload directory!</p>");
        }
    }
    
    if (!is_writable($upload_dir)) {
        chmod($upload_dir, 0777);
        if (!is_writable($upload_dir)) {
            die("<p style='color:red'>Upload directory is not writable!</p>");
        }
    }
    
    // Generate a unique filename
    $file_ext = strtolower(pathinfo($_FILES['test_image']['name'], PATHINFO_EXTENSION));
    $file_name = uniqid() . '_' . time() . '.' . $file_ext;
    $target_file = $upload_dir . $file_name;
    
    echo "<p>Target file path: " . $target_file . "</p>";
    
    // Check MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime_type = finfo_file($finfo, $_FILES['test_image']['tmp_name']);
    finfo_close($finfo);
    
    echo "<p>MIME type: " . $mime_type . "</p>";
    
    // Move the uploaded file
    if (move_uploaded_file($_FILES['test_image']['tmp_name'], $target_file)) {
        echo "<p style='color:green'>File uploaded successfully!</p>";
        echo "<p>File path: " . $target_file . "</p>";
        
        // Show the uploaded image if it's an image
        if (strpos($mime_type, 'image/') === 0) {
            echo "<p>Image preview:</p>";
            echo "<img src='/fypProject/uploads/" . $file_name . "' style='max-width: 300px;'>";
        }
    } else {
        echo "<p style='color:red'>Failed to move uploaded file!</p>";
        
        // Show detailed error information
        switch ($_FILES['test_image']['error']) {
            case UPLOAD_ERR_INI_SIZE:
                echo "The uploaded file exceeds the upload_max_filesize directive in php.ini.";
                break;
            case UPLOAD_ERR_FORM_SIZE:
                echo "The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form.";
                break;
            case UPLOAD_ERR_PARTIAL:
                echo "The uploaded file was only partially uploaded.";
                break;
            case UPLOAD_ERR_NO_FILE:
                echo "No file was uploaded.";
                break;
            case UPLOAD_ERR_NO_TMP_DIR:
                echo "Missing a temporary folder.";
                break;
            case UPLOAD_ERR_CANT_WRITE:
                echo "Failed to write file to disk.";
                break;
            case UPLOAD_ERR_EXTENSION:
                echo "A PHP extension stopped the file upload.";
                break;
            default:
                echo "Unknown upload error.";
                break;
        }
    }
} else {
    echo "<p style='color:red'>No file uploaded or there was an error with the upload.</p>";
    if (isset($_FILES['test_image'])) {
        echo "<p>Upload error code: " . $_FILES['test_image']['error'] . "</p>";
        
        // Explain the error code
        switch ($_FILES['test_image']['error']) {
            case UPLOAD_ERR_INI_SIZE:
                echo "The uploaded file exceeds the upload_max_filesize directive in php.ini.";
                break;
            case UPLOAD_ERR_FORM_SIZE:
                echo "The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form.";
                break;
            case UPLOAD_ERR_PARTIAL:
                echo "The uploaded file was only partially uploaded.";
                break;
            case UPLOAD_ERR_NO_FILE:
                echo "No file was uploaded.";
                break;
            case UPLOAD_ERR_NO_TMP_DIR:
                echo "Missing a temporary folder.";
                break;
            case UPLOAD_ERR_CANT_WRITE:
                echo "Failed to write file to disk.";
                break;
            case UPLOAD_ERR_EXTENSION:
                echo "A PHP extension stopped the file upload.";
                break;
            default:
                echo "Unknown upload error.";
                break;
        }
    }
}

echo "<p><a href='test_upload.php'>Back to upload test</a></p>";
