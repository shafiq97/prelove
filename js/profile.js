function openTab(tab) {
    const content = document.getElementById('tab-content');
    content.innerHTML = ''; // clear existing

    window.onload = function() {
        openTab('sell');
    };

    if (tab === 'sell') {
        content.innerHTML = '<p>Showing items for sale...</p>';
    } else if (tab === 'donate') {
        content.innerHTML = '<p>Showing donated items...</p>';
    } else if (tab === 'saved') {
        content.innerHTML = '<p>Showing saved outfits/clothes...</p>';
    } else if (tab === 'dashboard') {
        content.innerHTML = `
            <h3>Dashboard</h3>
            <ul>
                <li>Total Items Sold: 5</li>
                <li>Items Donated: 3</li>
                <li>Outfits Planned: 4</li>
            </ul>`;
    }
}

function openEditProfileModal() {
    document.getElementById('edit-profile-modal').style.display = 'block';
}

function closeEditProfileModal() {
    document.getElementById('edit-profile-modal').style.display = 'none';
}

function previewImage(event) {
    const file = event.target.files[0];
    const reader = new FileReader();
    reader.onload = function () {
        document.getElementById('profile-pic').src = reader.result;
    };
    if (file) {
        reader.readAsDataURL(file);
    }
}

function saveProfileChanges() {
    const newUsername = document.getElementById('new-username').value;
    const newEmail = document.getElementById('new-email').value;

    // Simulate saving to the database
    alert('Profile updated successfully!');

    // Update the profile page with the new information
    document.getElementById('username').innerText = newUsername;
    document.getElementById('email').innerText = newEmail;

    // Close the modal
    closeEditProfileModal();
}
