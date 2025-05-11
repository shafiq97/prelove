<?php
include 'db_connection.php'; // Include the database connection

$action = $_GET['action'] ?? '';
$data = json_decode(file_get_contents("php://input"), true);

if ($action == "fetch") {
    $result = $mysqli->query("SELECT * FROM outfits");
    $outfits = [];
    while ($row = $result->fetch_assoc()) {
        $outfits[] = $row;
    }
    echo json_encode($outfits);
}
elseif ($action == "add") {
    $name = $mysqli->real_escape_string($data['name']);
    $items = $mysqli->real_escape_string(json_encode($data['items']));
    $mysqli->query("INSERT INTO outfits (name, items) VALUES ('$name', '$items')");
}
elseif ($action == "update") {
    $id = (int) $data['id'];
    $name = $mysqli->real_escape_string($data['name']);
    $items = $mysqli->real_escape_string(json_encode($data['items']));
    $mysqli->query("UPDATE outfits SET name='$name', items='$items' WHERE id=$id");
}
elseif ($action == "delete") {
    $id = (int) $data['id'];
    $mysqli->query("DELETE FROM outfits WHERE id=$id");
}

$mysqli->close();
?>
