// Show Register form
function showRegister() {
    document.getElementById('login-form').style.display = 'none';
    document.getElementById('register-form').style.display = 'block';
}

// Show Login form
function showLogin() {
    document.getElementById('register-form').style.display = 'none';
    document.getElementById('login-form').style.display = 'block';
}

// Load Terms & Conditions into popup
function loadTerms(event) {
    event.preventDefault(); // Prevent default link behavior
    fetch('terms.html')
        .then(response => response.text())
        .then(html => {
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');
            const termsContent = doc.querySelector('main');
            document.getElementById('termsContent').innerHTML = termsContent ? termsContent.innerHTML : "Could not load terms.";
            document.getElementById('termsPopup').style.display = 'flex';
        })
        .catch(err => {
            document.getElementById('termsContent').innerText = "Failed to load Terms & Conditions.";
            document.getElementById('termsPopup').style.display = 'flex';
        });
}

// Accept terms: enable checkbox, close popup, and redirect to login.html#register
function acceptAndRedirect() {
    const termsCheckbox = document.getElementById("terms");
    const registerBtn = document.getElementById("register-btn");

    if (termsCheckbox) {
        termsCheckbox.disabled = false;
        termsCheckbox.checked = true;
    }
    if (registerBtn) {
        registerBtn.disabled = false;
    }

    document.getElementById("termsPopup").style.display = "none";

    // Redirect to login.html and show register form
    window.location.href = "login.html#register";
}

// Enable/disable Register button based on checkbox
document.addEventListener("DOMContentLoaded", function () {
    const termsCheckbox = document.getElementById("terms");
    const registerBtn = document.getElementById("register-btn");

    if (termsCheckbox && registerBtn) {
        termsCheckbox.addEventListener("change", function () {
            registerBtn.disabled = !this.checked;
        });
    }

    // Automatically show register form if redirected via #register
    if (window.location.hash === "#register") {
        showRegister();
    }
});

// Function to get query parameters from the URL
function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

// Handle "I Accept" button visibility based on the "from" parameter
document.addEventListener("DOMContentLoaded", function () {
    const from = getQueryParam("from");
    const acceptContainer = document.getElementById("acceptContainer");
    const backBtn = document.getElementById("backBtn");

    // Show Accept button only if coming from login
    if (from === "login") {
        acceptContainer.classList.remove("hidden");
        backBtn.classList.add("hidden"); // Hide back button in login flow
    }

    // Back button only works for settings
    if (from === "settings") {
        backBtn.classList.remove("hidden");
        backBtn.addEventListener("click", function () {
            window.location.href = "settings.html";
        });
    }
});

// Handle accept action when button is clicked
const acceptBtn = document.getElementById("acceptBtn");
if (acceptBtn) {
    acceptBtn.addEventListener("click", function () {
        // Redirect back to login.html and indicate register form + accepted
        window.location.href = "login.html?showRegister=true&accepted=true";
    });
}
