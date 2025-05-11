<?php
// Script to check PHP syntax of donation_api.php
$file = 'api/v1/donation_api.php';
$output = array();
$return_var = 0;

echo "<h1>PHP Syntax Checker</h1>";
echo "<h2>Checking: {$file}</h2>";
echo "<pre>";

// Try to use exec to run php -l
exec("php -l {$file} 2>&1", $output, $return_var);

if ($return_var === 0) {
    echo "No syntax errors detected in {$file}\n\n";
} else {
    echo "Syntax errors detected:\n";
    echo implode("\n", $output);
    echo "\n\n";
}

// Let's also check the file content
echo "File content for review:\n";
echo htmlspecialchars(file_get_contents($file));
echo "</pre>";
?>
