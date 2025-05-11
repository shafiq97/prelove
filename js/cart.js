// cart.js - Handles Cart Logic

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


// Load Cart Data on Page Load
document.addEventListener('DOMContentLoaded', function () {
    loadCart();
});

// Load Cart Items from Local Storage
function loadCart() {
    const cart = JSON.parse(localStorage.getItem('cart')) || [];
    const cartContainer = document.getElementById('cart');
    const subtotalElement = document.getElementById('subtotal');
    const totalElement = document.getElementById('total');
    const cartDataInput = document.getElementById('cartData');

    if (cart.length === 0) {
        cartContainer.innerHTML = '<p>Your cart is empty.</p>';
        subtotalElement.textContent = 'RM0.00';
        totalElement.textContent = 'RM0.00';
        return;
    }

    let subtotal = 0;
    const grouped = groupByStore(cart);

    cartContainer.innerHTML = '';

    for (const [store, items] of Object.entries(grouped)) {
        const storeBlock = document.createElement('div');
        storeBlock.className = 'store bg-white p-4 rounded-lg shadow-md';
        storeBlock.innerHTML = `<h3 class="font-semibold">${store}</h3>`;

        items.forEach(item => {
            subtotal += item.price * item.quantity;

            storeBlock.innerHTML += `
                <div class="item flex items-center mt-4">
                    <img src="${item.image}" alt="${item.name}" class="w-20 h-20 rounded-lg">
                    <div class="ml-4 flex-1">
                        <p class="text-lg">${item.name}</p>
                        <p class="text-sm text-gray-500">${item.variant}</p>
                        <p class="text-pink-500 font-semibold">RM${item.price.toFixed(2)}</p>
                        <p>Qty: ${item.quantity}</p>
                    </div>
                </div>`;
        });

        cartContainer.appendChild(storeBlock);
    }

    subtotalElement.textContent = `RM${subtotal.toFixed(2)}`;
    totalElement.textContent = `RM${subtotal.toFixed(2)}`;

    // Pass cart data to PHP for processing
    cartDataInput.value = JSON.stringify(cart);
}

// Helper: Group Items by Store
function groupByStore(cart) {
    return cart.reduce((grouped, item) => {
        grouped[item.store] = grouped[item.store] || [];
        grouped[item.store].push(item);
        return grouped;
    }, {});
}
