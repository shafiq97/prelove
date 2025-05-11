// Load History Data
document.addEventListener("DOMContentLoaded", () => {
    loadHistory();
    document.getElementById('search').addEventListener('input', searchHistory);
});

// Fetch History from PHP (localStorage can also be used)
function loadHistory() {
    fetch('history.php')
        .then(response => response.json())
        .then(data => {
            displayHistory(data);
        })
        .catch(err => console.error("Error loading history:", err));
}

// Display History Items
function displayHistory(history) {
    const container = document.getElementById('history-container');
    container.innerHTML = '';

    history.forEach(item => {
        const historyItem = document.createElement('div');
        historyItem.className = 'history-item';
        historyItem.dataset.category = item.category;

        historyItem.innerHTML = `
            <img src="${item.image}" alt="${item.title}">
            <div class="history-details">
                <p class="history-title">${item.title}</p>
                <p class="history-date">Date: ${item.date}</p>
                <p class="history-status">Status: ${item.status}</p>
            </div>
        `;

        container.appendChild(historyItem);
    });
}

// Filter History by Category
function filterHistory(category) {
    const items = document.querySelectorAll('.history-item');
    items.forEach(item => {
        item.style.display = (category === 'all' || item.dataset.category === category) ? 'flex' : 'none';
    });
}

// Search History
function searchHistory() {
    const query = this.value.toLowerCase();
    const items = document.querySelectorAll('.history-item');
    items.forEach(item => {
        item.style.display = item.textContent.toLowerCase().includes(query) ? 'flex' : 'none';
    });
}
