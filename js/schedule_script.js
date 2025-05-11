// Toggle Sidebar
document.getElementById('menu-toggle').addEventListener('click', function () {
    document.getElementById('sidebar').classList.toggle('-translate-x-full');
});

// Sidebar Logic
const sidebar = document.getElementById('sidebar');
const closeSidebarBtn = document.getElementById('close-sidebar');

// Close Sidebar on Back Button Click
closeSidebarBtn.addEventListener('click', () => {
    sidebar.classList.add('-translate-x-full');
});


// Active Navigation
const currentPage = window.location.pathname.split("/").pop();
const navItems = {
    "home.html": "nav-shop",
    "schedule.html": "nav-schedule",
    "sell.html": "nav-add",
    "planner.html": "nav-planner",
    "cart.html": "nav-cart"
};
if (navItems[currentPage]) {
    document.getElementById(navItems[currentPage]).classList.add('active');
}

// Load Events (from server)
function loadEvents() {
    fetch('get_events.php')
        .then(response => response.json())
        .then(events => {
            const eventList = document.getElementById('event-list');
            eventList.innerHTML = '';

            events.forEach(event => {
                const eventItem = document.createElement('div');
                eventItem.className = 'event-item';
                eventItem.innerHTML = `
                    <span>${event.title} - ${event.datetime} (${event.category})</span>
                    <button onclick="markCompleted(${event.id})">✔️</button>
                `;
                eventList.appendChild(eventItem);
            });
        });
}

// Mark Event as Completed
function markCompleted(id) {
    fetch(`mark_completed.php?id=${id}`, { method: 'POST' })
        .then(() => loadEvents());
}

window.onload = loadEvents;
