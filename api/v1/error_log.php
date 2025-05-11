<?php
// Simple script to show the most recent PHP errors
echo "<h1>PHP Error Log</h1>";
echo "<pre>";
echo shell_exec("tail -n 50 /Applications/XAMPP/xamppfiles/htdocs/fypProject/logs/api_error.log");
echo "</pre>";
?>
