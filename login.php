<?php
$host = 'localhost';
$dbname = 'prelove_db';
$username = 'root';
$password = '';

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        session_start();

        $user = trim($_POST['username']); // Remove any extra spaces
        $pass = $_POST['password'];

        // Simple input validation (ensure inputs aren't empty)
        if (empty($user) || empty($pass)) {
            echo "Both username and password are required.";
            exit;
        }

        $stmt = $conn->prepare("SELECT * FROM users WHERE username = :username");
        $stmt->bindParam(':username', $user);
        $stmt->execute();
        $user_data = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user_data && password_verify($pass, $user_data['password'])) {
            // Store user session securely
            $_SESSION['user_id'] = $user_data['id']; // Store user ID in session
            $_SESSION['username'] = $user_data['username']; // Optionally store username for display
            $_SESSION['role'] = $user_data['role']; // Assuming 'role' field in the database

            // Redirect based on role
            if ($_SESSION['role'] == 'admin') {
                header("Location: admin_dashboard.html"); // Redirect to admin's homepage
            } elseif ($_SESSION['role'] == 'donation_center') {
                header("Location: donation_center_home.html"); // Redirect to donation center's page
            } else {
                header("Location: home.html"); // Redirect to user homepage
            }
            exit;
        } else {
            echo "Invalid credentials.";
        }
    }
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
?>
