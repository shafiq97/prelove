<?php
include 'db_connection.php'; // ✅ Include database connection

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $item = htmlspecialchars($_POST['item']);
    $price = floatval($_POST['price']);
    $category = htmlspecialchars($_POST['category']);

    // ✅ Insert item into the database
    $stmt = $conn->prepare("INSERT INTO products (name, price, category) VALUES (?, ?, ?)");
    $stmt->bind_param("sds", $item, $price, $category);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => "Item '$item' added successfully"]);
    } else {
        echo json_encode(['status' => 'error', 'message' => "Failed to add item"]);
    }
    exit;
}

// ✅ Secure search & filter query
$search = $_GET['search'] ?? '';
$category = $_GET['category'] ?? '';
$price = $_GET['price'] ?? '';

$sql = "SELECT * FROM products WHERE name LIKE ?";
$params = ["%$search%"];

if ($category) {
    $sql .= " AND category = ?";
    $params[] = $category;
}

if ($price == "low") {
    $sql .= " AND price < ?";
    $params[] = 50;
} elseif ($price == "medium") {
    $sql .= " AND price BETWEEN ? AND ?";
    $params[] = 50;
    $params[] = 100;
} elseif ($price == "high") {
    $sql .= " AND price > ?";
    $params[] = 100;
}

// ✅ Use prepared statements
$stmt = $conn->prepare($sql);
$stmt->execute($params);
$result = $stmt->get_result();

$products = [];
while ($row = $result->fetch_assoc()) {
    $products[] = $row;
}

echo json_encode($products);
$conn->close();
?>
