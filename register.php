<?php
$host = 'localhost';
$dbname = 'prelove_db';
$username = 'root';
$password = '';

// Google reCAPTCHA secret key
$recaptcha_secret = '6LdDyAErAAAAAM4tRitCAW3Mchl0YB2PrtJDCNRk';

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $full_name = $_POST['full_name'];
        $email = $_POST['new_email'];
        $phone = $_POST['phone'];
        $address = $_POST['address'];
        $password = password_hash($_POST['new_password'], PASSWORD_DEFAULT);
        $recaptcha_response = $_POST['g-recaptcha-response'];

        // Verify reCAPTCHA
        $recaptcha_url = 'https://www.google.com/recaptcha/api/siteverify';
        $recaptcha_data = [
            'secret' => $recaptcha_secret,
            'response' => $recaptcha_response
        ];
        $recaptcha_options = [
            'http' => [
                'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
                'method'  => 'POST',
                'content' => http_build_query($recaptcha_data)
            ]
        ];
        $recaptcha_context  = stream_context_create($recaptcha_options);
        $recaptcha_result = file_get_contents($recaptcha_url, false, $recaptcha_context);
        $recaptcha_result = json_decode($recaptcha_result, true);

        if (!$recaptcha_result['success']) {
            echo "reCAPTCHA verification failed!";
            exit();
        }

        // Check if email already exists
        $stmt = $conn->prepare("SELECT * FROM users WHERE email = :email");
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            echo "Email already in use!";
        } else {
            // Insert user
            $stmt = $conn->prepare("INSERT INTO users (full_name, email, phone, address, password) VALUES (:full_name, :email, :phone, :address, :password)");
            $stmt->bindParam(':full_name', $full_name);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':phone', $phone);
            $stmt->bindParam(':address', $address);
            $stmt->bindParam(':password', $password);
            if ($stmt->execute()) {
                // Send Email Confirmation
                $to = $email;
                $subject = "Welcome to Pre-Love Closet Manager!";
                $message = "Hello $full_name,\n\nThank you for registering! Your account has been successfully created.";
                $headers = "From: noreply@yourwebsite.com";

                mail($to, $subject, $message, $headers);
                echo "Registration successful!";
            } else {
                echo "Error during registration.";
            }
        }
    }
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}

<div class="terms-container">
        <input type="checkbox" id="terms" name="terms" disabled>
        <label for="terms">
            I have read and agree to 
            <a href="terms.txt" onclick="loadTerms(event)">Terms & Conditions</a>
        </label>
    </div>

    <button id="register-btn" type="submit" disabled>Register</button>
</form>

<!-- Popup -->
<div class="popup" id="termsPopup">
    <div class="popup-content">
        <p id="termsContent">Loading terms...</p>
        <button onclick="acceptTerms()">I Accept</button>
    </div>
</div>

if (!isset($_POST['terms'])) {
    echo "You must accept the terms and conditions!";
    exit();
}

?>
