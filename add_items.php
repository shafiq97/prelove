<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $item_name = $_POST["item_name"];
    $item_description = $_POST["item_description"];
    $item_condition = $_POST["item_condition"];
    $action = $_POST["action"];
    $camera_image = $_POST["camera_image"];

    // Handling image upload
    $target_dir = "uploads/";
    $image_paths = [];

    foreach ($_FILES["item_image"]["tmp_name"] as $key => $tmp_name) {
        $image_name = basename($_FILES["item_image"]["name"][$key]);
        $target_file = $target_dir . $image_name;
        
        if (move_uploaded_file($_FILES["item_image"]["tmp_name"][$key], $target_file)) {
            $image_paths[] = $target_file;
        }
    }

    // Handling camera image (if captured)
    if (!empty($camera_image)) {
        $camera_image_data = base64_decode(preg_replace('#^data:image/\w+;base64,#i', '', $camera_image));
        $camera_image_name = "uploads/captured_" . time() . ".png";
        file_put_contents($camera_image_name, $camera_image_data);
        $image_paths[] = $camera_image_name;
    }

    // Store item details in database
    $conn = new mysqli("localhost", "root", "", "prelove_db");
    $query = "INSERT INTO items (name, description, condition, images, type) 
              VALUES ('$item_name', '$item_description', '$item_condition', '".json_encode($image_paths)."', '$action')";

    if ($conn->query($query)) {
        echo "Item added successfully!";
    } else {
        echo "Error: " . $conn->error;
    }
}

    if ($action == "sell") {
        $item_price = $_POST["item_price"];
        // Store selling item details in database
        $query = "INSERT INTO items (name, description, condition, price, images, type) 
                  VALUES ('$item_name', '$item_description', '$item_condition', '$item_price', '".json_encode($image_paths)."', 'sell')";
    } else {
        $donation_center = $_POST["donation_center"];
        $donation_date = $_POST["donation_date"];
        // Store donation item details in database
        $query = "INSERT INTO items (name, description, condition, images, type, donation_center, donation_date) 
                  VALUES ('$item_name', '$item_description', '$item_condition', '".json_encode($image_paths)."', 'donate', '$donation_center', '$donation_date')";
    }

    // Database connection (Replace with actual credentials)
    $conn = new mysqli("localhost", "root", "", "prelove_db");
    if ($conn->query($query)) {
        echo "Item added successfully!";
    } else {
        echo "Error: " . $conn->error;
    }
}
?>
