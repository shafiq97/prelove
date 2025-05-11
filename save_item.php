<?php
// Database connection (Replace with your actual DB credentials)
$host = "localhost";
$user = "root";
$password = "";
$dbname = "prelove_db";

$conn = new mysqli($host, $user, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Handle incoming request
$data = json_decode(file_get_contents("php://input"), true);
$action = $data["action"];
$item = $data["item"];

if ($action == "cart") {
    $query = "INSERT INTO cart (name, category, price, image) VALUES (?, ?, ?, ?)";
} else if ($action == "planner") {
    $query = "INSERT INTO planner (name, category, price, image) VALUES (?, ?, ?, ?)";
} else {
    echo "Invalid action.";
    exit;
}

$stmt = $conn->prepare($query);
$stmt->bind_param("ssds", $item["name"], $item["category"], $item["price"], $item["img"]);
if ($stmt->execute()) {
    echo ucfirst($action) . " item saved successfully!";
} else {
    echo "Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>
