<?php
include 'db_connection.php'; // ✅ Include database connection

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['cartData'])) {
        $cartData = json_decode($_POST['cartData'], true);

        if (!empty($cartData)) {
            echo "<h1>Order Summary</h1>";
            $total = 0;
            $order_id = uniqid(); // Generate unique order ID

            foreach ($cartData as $item) {
                echo "<p><strong>Store:</strong> {$item['store']}</p>";
                echo "<p><strong>Item:</strong> {$item['name']}</p>";
                echo "<p><strong>Variant:</strong> {$item['variant']}</p>";
                echo "<p><strong>Price:</strong> RM" . number_format($item['price'], 2) . "</p>";
                echo "<p><strong>Quantity:</strong> {$item['quantity']}</p><hr>";

                $total += $item['price'] * $item['quantity'];

                // ✅ Store order details in the database
                $stmt = $conn->prepare("INSERT INTO orders (order_id, store, item, variant, price, quantity) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->bind_param("ssssdi", $order_id, $item['store'], $item['name'], $item['variant'], $item['price'], $item['quantity']);
                $stmt->execute();
            }

            echo "<h2>Total: RM" . number_format($total, 2) . "</h2>";

            // ✅ Redirect to confirmation page
            header("Location: order_confirmation.php?order_id=$order_id");
            exit();
        } else {
            echo "<p>Error: Cart is empty!</p>";
        }
    }
} else {
    echo "<p>Invalid request method!</p>";
}
?>
