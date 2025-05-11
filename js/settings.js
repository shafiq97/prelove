// Dark Mode Toggle
const darkModeToggle = document.getElementById('dark-mode-toggle');
darkModeToggle.addEventListener('change', () => {
    document.body.classList.toggle('dark-mode', darkModeToggle.checked);
    localStorage.setItem('darkMode', darkModeToggle.checked);
});

// Restore Dark Mode Preference
if (localStorage.getItem('darkMode') === 'true') {
    darkModeToggle.checked = true;
    document.body.classList.add('dark-mode');
}

// Clear Activity History
document.getElementById('clear-history').addEventListener('click', () => {
    if (confirm('Are you sure you want to clear your activity history?')) {
        localStorage.removeItem('cart');
        alert('Activity history cleared.');
    }
});

// Export Data (Placeholder Logic)
document.getElementById('export-data').addEventListener('click', () => {
    alert('Your data export will be available soon!');
});

// Logout from All Devices (Placeholder Logic)
document.getElementById('logout-all').addEventListener('click', () => {
    alert('You have been logged out from all devices.');
});

// Privacy Toggle
const privacyToggle = document.getElementById('privacy-toggle');
privacyToggle.addEventListener('change', () => {
    alert(privacyToggle.checked ? 'Profile is now private.' : 'Profile is now public.');
});
