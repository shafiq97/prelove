<?php
session_start();
session_destroy();
header("Location: login.html");
die("Redirecting to login..");
exit();
?>
