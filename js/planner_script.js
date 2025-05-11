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
document.addEventListener("DOMContentLoaded", function () {
    fetchOutfits();
});

function fetchOutfits() {
    fetch("planner.php?action=fetch")
        .then(response => response.json())
        .then(data => {
            let outfitList = document.getElementById("outfitList");
            outfitList.innerHTML = "";
            data.forEach(outfit => {
                outfitList.innerHTML += `
                    <div>
                        <h3>${outfit.name}</h3>
                        <p>Items: ${JSON.parse(outfit.items).join(", ")}</p>
                        <button onclick="editOutfit(${outfit.id}, '${outfit.name}', '${outfit.items}')">Edit</button>
                        <button onclick="deleteOutfit(${outfit.id})">Delete</button>
                    </div>
                `;
            });
        });
}

function addOutfit() {
    let name = document.getElementById("outfitName").value;
    let items = document.getElementById("outfitItems").value.split(",");

    fetch("planner.php?action=add", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, items })
    }).then(() => fetchOutfits());
}

function editOutfit(id, name, items) {
    let newName = prompt("Edit Outfit Name:", name);
    let newItems = prompt("Edit Items (comma-separated):", JSON.parse(items).join(", "));

    if (newName && newItems) {
        fetch("planner.php?action=update", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ id, name: newName, items: newItems.split(",") })
        }).then(() => fetchOutfits());
    }
}

function deleteOutfit(id) {
    if (confirm("Are you sure you want to delete this outfit?")) {
        fetch("planner.php?action=delete", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ id })
        }).then(() => fetchOutfits());
    }
}