document.addEventListener('DOMContentLoaded', () => {
    loadNotifications();
});

// Sample notifications (replace with backend data later)
const notifications = [
    { type: "Sell", message: "Your vintage jacket has been sold!", time: "2 hours ago" },
    { type: "Donate", message: "Donation pickup is scheduled for March 30.", time: "1 day ago" },
    { type: "Buy", message: "Your thrifted jeans are on the way!", time: "3 days ago" },
    { type: "Reminder", message: "Outfit reminder: Summer Look tomorrow.", time: "5 days ago" },
];

function loadNotifications() {
    const container = document.getElementById('notification-container');
    if (notifications.length === 0) {
        container.innerHTML = '<p>No new notifications.</p>';
        return;
    }

    notifications.forEach(notif => {
        const notifElement = document.createElement('div');
        notifElement.className = 'notification';
        notifElement.innerHTML = `
            <div>
                <p class="type">${notif.type}</p>
                <p>${notif.message}</p>
            </div>
            <p class="time">${notif.time}</p>
        `;
        container.appendChild(notifElement);
    });
}
