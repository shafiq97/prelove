<?php
$mysqli = new mysqli("localhost", "root", "", "preloved_closet_db");

if ($mysqli->connect_error) {
  die("Connection failed: " . $mysqli->connect_error);
}

function showUsers() {
  global $mysqli;
  $result = $mysqli->query("SELECT * FROM users");
  echo "<h2>Users</h2><table border='1'><tr><th>ID</th><th>Username</th><th>Email</th></tr>";
  while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['user_id']}</td><td>{$row['username']}</td><td>{$row['email']}</td></tr>";
  }
  echo "</table>";
}

function showItems() {
  global $mysqli;
  $result = $mysqli->query("SELECT * FROM items");
  echo "<h2>Items</h2><table border='1'><tr><th>ID</th><th>Name</th><th>Category</th><th>Status</th></tr>";
  while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['item_id']}</td><td>{$row['item_name']}</td><td>{$row['category']}</td><td>{$row['status']}</td></tr>";
  }
  echo "</table>";
}

function showDonations() {
  global $mysqli;
  $result = $mysqli->query("SELECT * FROM events WHERE category = 'Donate'");
  echo "<h2>Donations</h2><table border='1'><tr><th>Title</th><th>Date</th><th>Completed</th></tr>";
  while ($row = $result->fetch_assoc()) {
    $completed = $row['completed'] ? 'Yes' : 'No';
    echo "<tr><td>{$row['title']}</td><td>{$row['event_date']}</td><td>$completed</td></tr>";
  }
  echo "</table>";
}
?>
