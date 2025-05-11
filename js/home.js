// Toggle Sidebar
document.getElementById('menu-toggle').addEventListener('click', function () {
    document.getElementById('sidebar').classList.toggle('-translate-x-full');
});

// Close Sidebar on Back Button Click
document.getElementById('close-sidebar').addEventListener('click', () => {
    document.getElementById('sidebar').classList.add('-translate-x-full');
});

// Set Active Navigation Item
const currentPage = window.location.pathname.split("/").pop();
const navItems = {
    "home.html": "nav-shop",
    "schedule.html": "nav-schedule",
    "add_item.html": "nav-add",
    "planner.html": "nav-planner",
    "cart.html": "nav-cart"
};
if (navItems[currentPage]) {
    document.getElementById(navItems[currentPage]).classList.add('text-pink-500');
}

// Sample Product Data (Replace with data from database)
const products = [
    { id: 1, name: "Vintage Jacket", category: "Clothes", price: 40, img: "https://via.placeholder.com/300" },
    { id: 2, name: "Designer Handbag", category: "Bags", price: 120, img: "https://via.placeholder.com/300" },
    { id: 3, name: "Classic Sneakers", category: "Shoes", price: 80, img: "https://via.placeholder.com/300" }
];

// Load and Display Products
function loadProducts(filtered = products) {
    const productList = document.getElementById("product-list");
    productList.innerHTML = "";

    filtered.forEach(product => {
        const productCard = document.createElement("div");
        productCard.className = "product-card bg-white p-4 rounded-lg shadow-md";
        productCard.innerHTML = `
            <img src="${product.img}" alt="${product.name}" class="w-full h-40 object-cover">
            <h3 class="text-lg font-semibold">${product.name}</h3>
            <p class="text-pink-500">RM${product.price}</p>
            <div class="mt-2 flex gap-2">
                <button class="add-to-cart bg-green-500 text-white px-3 py-1 rounded" data-id="${product.id}">🛒 Cart</button>
                <button class="add-to-planner bg-blue-500 text-white px-3 py-1 rounded" data-id="${product.id}">👗 Planner</button>
            </div>
        `;
        productList.appendChild(productCard);
    });

    // Add event listeners for cart and planner buttons
    document.querySelectorAll(".add-to-cart").forEach(button => {
        button.addEventListener("click", function () {
            const productId = this.getAttribute("data-id");
            const product = products.find(p => p.id == productId);
            addToCart(product);
        });
    });

    document.querySelectorAll(".add-to-planner").forEach(button => {
        button.addEventListener("click", function () {
            const productId = this.getAttribute("data-id");
            const product = products.find(p => p.id == productId);
            addToPlanner(product);
        });
    });
}

// Add to Cart
function addToCart(product) {
    fetch("save_item.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "cart", item: product })
    }).then(response => response.text()).then(data => {
        alert(data);
        window.location.href = "cart.html";
    }).catch(error => console.error("Error:", error));
}

// Add to Planner
function addToPlanner(product) {
    fetch("save_item.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "planner", item: product })
    }).then(response => response.text()).then(data => {
        alert(data);
        window.location.href = "planner.html";
    }).catch(error => console.error("Error:", error));
}

// Filter Products
function filterProducts() {
    const search = document.getElementById("search").value.toLowerCase();
    const category = document.getElementById("category").value;
    const price = document.getElementById("price").value;

    const filtered = products.filter(p => {
        const matchesName = p.name.toLowerCase().includes(search);
        const matchesCategory = category === "" || p.category === category;
        const matchesPrice = (
            price === "" ||
            (price === "low" && p.price < 50) ||
            (price === "medium" && p.price >= 50 && p.price <= 100) ||
            (price === "high" && p.price > 100)
        );
        return matchesName && matchesCategory && matchesPrice;
    });

    loadProducts(filtered);
}

// Trigger Filter on Enter or Magnifier Click
function triggerSearch() {
    filterProducts();
}

// Hook up filters
document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("search").addEventListener("input", filterProducts);
    document.getElementById("search").addEventListener("keydown", function (e) {
        if (e.key === "Enter") {
            triggerSearch();
        }
    });

    document.getElementById("search-btn").addEventListener("click", function () {
        triggerSearch();
    });

    document.getElementById("category").addEventListener("change", filterProducts);
    document.getElementById("price").addEventListener("change", filterProducts);

    loadProducts(); // Initial load
});
