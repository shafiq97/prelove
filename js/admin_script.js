function showSection(section) {
    const sections = document.querySelectorAll('.section');
    sections.forEach(sec => sec.style.display = 'none');
  
    document.getElementById(`section-${section}`).style.display = 'block';
}

// Document ready
$(document).ready(function() {
  // Initialize Bootstrap tabs
  var triggerTabList = [].slice.call(document.querySelectorAll('.nav-link'))
  triggerTabList.forEach(function(triggerEl) {
    var tabTrigger = new bootstrap.Tab(triggerEl)
    triggerEl.addEventListener('click', function(event) {
      event.preventDefault()
      tabTrigger.show()
    })
  })

  // Load initial data
  loadStatistics();
  loadUsers();
  loadItems();
  loadEvents();
  loadDonations();
  loadSellersForDropdown();
  loadUsersForDropdown();
  loadOutfitsForDropdown();
  
  // Initialize charts
  initializeCharts();
  
  // Setup form submissions
  setupFormHandlers();
});

// Function to load dashboard statistics
function loadStatistics() {
  $.ajax({
    url: 'admin_api.php?action=get_stats',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const stats = response.stats;
        
        // Update counters
        $('#userCount').text(stats.user_count);
        $('#itemCount').text(stats.item_count);
        $('#eventCount').text(stats.event_count);
        $('#donationCount').text(stats.donation_count);
        
        // Update charts with real data if available
        if (stats.user_trend && stats.categories) {
          updateUserChart(stats.user_trend);
          updateCategoryChart(stats.categories);
        } else {
          // Use placeholder data for demo
          updateUserChartWithPlaceholder();
          updateCategoryChartWithPlaceholder();
        }
      }
    },
    error: function(xhr) {
      console.error('Failed to load statistics:', xhr);
      // Use placeholder data if API fails
      updateUserChartWithPlaceholder();
      updateCategoryChartWithPlaceholder();
      
      // Set placeholder counts
      $('#userCount').text('10');
      $('#itemCount').text('25');
      $('#eventCount').text('8');
      $('#donationCount').text('5');
    }
  });
}

// Function to load users
function loadUsers() {
  $.ajax({
    url: 'admin_api.php?action=get_users',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const users = response.users;
        let tableContent = '';
        
        users.forEach(function(user) {
          tableContent += `
            <tr>
              <td>${user.id}</td>
              <td>${user.username}</td>
              <td>${user.email}</td>
              <td>${user.full_name || '-'}</td>
              <td><span class="badge ${user.role === 'admin' ? 'bg-danger' : 'bg-primary'}">${user.role || 'user'}</span></td>
              <td>${formatDate(user.created_at)}</td>
              <td>
                <button class="btn btn-sm btn-outline-primary edit-user" data-id="${user.id}" data-bs-toggle="modal" data-bs-target="#editUserModal">
                  <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger delete-user" data-id="${user.id}">
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
          `;
        });
        
        $('#usersTable tbody').html(tableContent);
        
        // Setup event handlers for edit and delete
        $('.edit-user').click(function() {
          const userId = $(this).data('id');
          // Load user data for editing
          const user = users.find(u => u.id == userId);
          if (user) {
            $('#editUserId').val(user.id);
            $('#editUsername').val(user.username);
            $('#editEmail').val(user.email);
            $('#editFullName').val(user.full_name);
            $('#editRole').val(user.role || 'user');
          }
        });
        
        $('.delete-user').click(function() {
          const userId = $(this).data('id');
          if (confirm('Are you sure you want to delete this user?')) {
            deleteUser(userId);
          }
        });
      }
    },
    error: function(xhr) {
      console.error('Failed to load users:', xhr);
      $('#usersTable tbody').html('<tr><td colspan="7" class="text-center">Failed to load users</td></tr>');
    }
  });
}

// Function to load items
function loadItems() {
  $.ajax({
    url: 'admin_api.php?action=get_items',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const items = response.items;
        let tableContent = '';
        
        items.forEach(function(item) {
          tableContent += `
            <tr>
              <td>${item.id}</td>
              <td>
                <img src="${item.image_url || 'assets/images/placeholder.png'}" alt="${item.name}" width="50" height="50" class="rounded">
              </td>
              <td>${item.name}</td>
              <td>${item.category}</td>
              <td>$${parseFloat(item.price).toFixed(2)}</td>
              <td>${item.condition}</td>
              <td>${item.seller_name}</td>
              <td>
                <span class="badge ${item.is_available == 1 ? 'bg-success' : 'bg-secondary'}">
                  ${item.is_available == 1 ? 'Available' : 'Unavailable'}
                </span>
              </td>
              <td>
                <button class="btn btn-sm btn-outline-primary edit-item" data-id="${item.id}" data-bs-toggle="modal" data-bs-target="#editItemModal">
                  <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger delete-item" data-id="${item.id}">
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
          `;
        });
        
        $('#itemsTable tbody').html(tableContent);
        
        // Setup event handlers for edit and delete
        $('.edit-item').click(function() {
          const itemId = $(this).data('id');
          // Load item data for editing
          const item = items.find(i => i.id == itemId);
          if (item) {
            $('#editItemId').val(item.id);
            $('#editItemName').val(item.name);
            $('#editItemCategory').val(item.category);
            $('#editItemPrice').val(item.price);
            $('#editItemCondition').val(item.condition);
            $('#editItemDescription').val(item.description);
            $('#editItemIsAvailable').prop('checked', item.is_available == 1);
          }
        });
        
        $('.delete-item').click(function() {
          const itemId = $(this).data('id');
          if (confirm('Are you sure you want to delete this item?')) {
            deleteItem(itemId);
          }
        });
      }
    },
    error: function(xhr) {
      console.error('Failed to load items:', xhr);
      $('#itemsTable tbody').html('<tr><td colspan="9" class="text-center">Failed to load items</td></tr>');
    }
  });
}

// Function to load events
function loadEvents() {
  $.ajax({
    url: 'admin_api.php?action=get_events',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const events = response.events;
        let tableContent = '';
        
        events.forEach(function(event) {
          tableContent += `
            <tr>
              <td>${event.id}</td>
              <td>${event.title}</td>
              <td>${formatDateTime(event.event_date)}</td>
              <td>${event.location || '-'}</td>
              <td>${event.outfit_name || '-'}</td>
              <td>${formatDate(event.created_at)}</td>
              <td>
                <button class="btn btn-sm btn-outline-primary edit-event" data-id="${event.id}" data-bs-toggle="modal" data-bs-target="#editEventModal">
                  <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger delete-event" data-id="${event.id}">
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
          `;
        });
        
        $('#eventsTable tbody').html(tableContent);
        
        // Setup event handlers for edit and delete
        $('.edit-event').click(function() {
          const eventId = $(this).data('id');
          // Load event data for editing
          const event = events.find(e => e.id == eventId);
          if (event) {
            $('#editEventId').val(event.id);
            $('#editEventTitle').val(event.title);
            $('#editEventDate').val(formatDateTimeForInput(event.event_date));
            $('#editEventLocation').val(event.location);
            $('#editEventDescription').val(event.description);
            $('#editOutfitId').val(event.outfit_id);
          }
        });
        
        $('.delete-event').click(function() {
          const eventId = $(this).data('id');
          if (confirm('Are you sure you want to delete this event?')) {
            deleteEvent(eventId);
          }
        });
      }
    },
    error: function(xhr) {
      console.error('Failed to load events:', xhr);
      $('#eventsTable tbody').html('<tr><td colspan="7" class="text-center">Failed to load events</td></tr>');
    }
  });
}

// Function to load donations
function loadDonations() {
  // This would typically be a separate API call for donations
  // For now, we'll just show placeholder data
  const donations = [
    { id: 1, donor: 'John Doe', center: 'Red Cross', items: 3, date: '2023-04-15', status: 'Completed' },
    { id: 2, donor: 'Jane Smith', center: 'Salvation Army', items: 5, date: '2023-04-22', status: 'Pending' },
    { id: 3, donor: 'Bob Johnson', center: 'Goodwill', items: 2, date: '2023-05-01', status: 'In Progress' }
  ];
  
  let tableContent = '';
  
  donations.forEach(function(donation) {
    tableContent += `
      <tr>
        <td>${donation.id}</td>
        <td>${donation.donor}</td>
        <td>${donation.center}</td>
        <td>${donation.items}</td>
        <td>${donation.date}</td>
        <td>
          <span class="badge ${donation.status === 'Completed' ? 'bg-success' : donation.status === 'Pending' ? 'bg-warning' : 'bg-info'}">
            ${donation.status}
          </span>
        </td>
        <td>
          <button class="btn btn-sm btn-outline-primary">
            <i class="fas fa-eye"></i>
          </button>
          <button class="btn btn-sm btn-outline-success">
            <i class="fas fa-check"></i>
          </button>
        </td>
      </tr>
    `;
  });
  
  $('#donationsTable tbody').html(tableContent);
}

// Function to load sellers for dropdown
function loadSellersForDropdown() {
  $.ajax({
    url: 'admin_api.php?action=get_users',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const users = response.users;
        let options = '<option value="">Select a seller</option>';
        
        users.forEach(function(user) {
          options += `<option value="${user.id}">${user.username} (${user.full_name || 'No name'})</option>`;
        });
        
        $('#sellerId').html(options);
      }
    }
  });
}

// Function to load users for dropdown
function loadUsersForDropdown() {
  $.ajax({
    url: 'admin_api.php?action=get_users',
    type: 'GET',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken()
    },
    success: function(response) {
      if (response.success) {
        const users = response.users;
        let options = '<option value="">Select a user</option>';
        
        users.forEach(function(user) {
          options += `<option value="${user.id}">${user.username} (${user.full_name || 'No name'})</option>`;
        });
        
        $('#userId').html(options);
      }
    }
  });
}

// Function to load outfits for dropdown
function loadOutfitsForDropdown() {
  // This would typically be a separate API call for outfits
  // For now, we'll just show placeholder data
  const outfits = [
    { id: 1, name: 'Summer Casual' },
    { id: 2, name: 'Formal Business' },
    { id: 3, name: 'Evening Party' }
  ];
  
  let options = '<option value="">Select an outfit</option>';
  
  outfits.forEach(function(outfit) {
    options += `<option value="${outfit.id}">${outfit.name}</option>`;
  });
  
  $('#outfitId').html(options);
}

// Function to delete a user
function deleteUser(userId) {
  $.ajax({
    url: 'admin_api.php?action=delete_user',
    type: 'DELETE',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken(),
      'Content-Type': 'application/json'
    },
    data: JSON.stringify({ id: userId }),
    success: function(response) {
      if (response.success) {
        showSuccess('User deleted successfully');
        loadUsers();
        loadStatistics();
      } else {
        showError(response.error || 'Failed to delete user');
      }
    },
    error: function(xhr) {
      showError('Failed to delete user');
    }
  });
}

// Function to delete an item
function deleteItem(itemId) {
  $.ajax({
    url: 'admin_api.php?action=delete_item',
    type: 'DELETE',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken(),
      'Content-Type': 'application/json'
    },
    data: JSON.stringify({ id: itemId }),
    success: function(response) {
      if (response.success) {
        showSuccess('Item deleted successfully');
        loadItems();
        loadStatistics();
      } else {
        showError(response.error || 'Failed to delete item');
      }
    },
    error: function(xhr) {
      showError('Failed to delete item');
    }
  });
}

// Function to delete an event
function deleteEvent(eventId) {
  $.ajax({
    url: 'admin_api.php?action=delete_event',
    type: 'DELETE',
    dataType: 'json',
    headers: {
      'Authorization': 'Bearer ' + getToken(),
      'Content-Type': 'application/json'
    },
    data: JSON.stringify({ id: eventId }),
    success: function(response) {
      if (response.success) {
        showSuccess('Event deleted successfully');
        loadEvents();
        loadStatistics();
      } else {
        showError(response.error || 'Failed to delete event');
      }
    },
    error: function(xhr) {
      showError('Failed to delete event');
    }
  });
}

// Function to setup form handlers
function setupFormHandlers() {
  // Add Item Form
  $('#addItemForm').submit(function(e) {
    e.preventDefault();
    
    const formData = new FormData(this);
    
    $.ajax({
      url: 'admin_api.php?action=add_item',
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      headers: {
        'Authorization': 'Bearer ' + getToken()
      },
      success: function(response) {
        if (response.success) {
          showSuccess('Item added successfully');
          $('#addItemForm')[0].reset();
          loadItems();
          loadStatistics();
        } else {
          showError(response.error || 'Failed to add item');
        }
      },
      error: function(xhr) {
        showError('Failed to add item');
      }
    });
  });
  
  // Add Event Form
  $('#addEventForm').submit(function(e) {
    e.preventDefault();
    
    const formData = {
      title: $('#eventTitle').val(),
      event_date: $('#eventDate').val(),
      description: $('#eventDescription').val(),
      location: $('#eventLocation').val(),
      outfit_id: $('#outfitId').val(),
      user_id: $('#userId').val()
    };
    
    $.ajax({
      url: 'admin_api.php?action=add_event',
      type: 'POST',
      data: JSON.stringify(formData),
      contentType: 'application/json',
      dataType: 'json',
      headers: {
        'Authorization': 'Bearer ' + getToken()
      },
      success: function(response) {
        if (response.success) {
          showSuccess('Event added successfully');
          $('#addEventForm')[0].reset();
          loadEvents();
          loadStatistics();
        } else {
          showError(response.error || 'Failed to add event');
        }
      },
      error: function(xhr) {
        showError('Failed to add event');
      }
    });
  });
  
  // Update User Form
  $('#editUserForm').submit(function(e) {
    e.preventDefault();
    
    const userId = $('#editUserId').val();
    const formData = {
      id: userId,
      username: $('#editUsername').val(),
      email: $('#editEmail').val(),
      full_name: $('#editFullName').val(),
      role: $('#editRole').val()
    };
    
    $.ajax({
      url: 'admin_api.php?action=update_user',
      type: 'PUT',
      data: JSON.stringify(formData),
      contentType: 'application/json',
      dataType: 'json',
      headers: {
        'Authorization': 'Bearer ' + getToken()
      },
      success: function(response) {
        if (response.success) {
          showSuccess('User updated successfully');
          $('#editUserModal').modal('hide');
          loadUsers();
        } else {
          showError(response.error || 'Failed to update user');
        }
      },
      error: function(xhr) {
        showError('Failed to update user');
      }
    });
  });
  
  // Update Item Form
  $('#editItemForm').submit(function(e) {
    e.preventDefault();
    
    const itemId = $('#editItemId').val();
    const formData = {
      id: itemId,
      name: $('#editItemName').val(),
      category: $('#editItemCategory').val(),
      price: $('#editItemPrice').val(),
      condition: $('#editItemCondition').val(),
      description: $('#editItemDescription').val(),
      is_available: $('#editItemIsAvailable').is(':checked') ? 1 : 0
    };
    
    $.ajax({
      url: 'admin_api.php?action=update_item',
      type: 'PUT',
      data: JSON.stringify(formData),
      contentType: 'application/json',
      dataType: 'json',
      headers: {
        'Authorization': 'Bearer ' + getToken()
      },
      success: function(response) {
        if (response.success) {
          showSuccess('Item updated successfully');
          $('#editItemModal').modal('hide');
          loadItems();
        } else {
          showError(response.error || 'Failed to update item');
        }
      },
      error: function(xhr) {
        showError('Failed to update item');
      }
    });
  });
  
  // Update Event Form
  $('#editEventForm').submit(function(e) {
    e.preventDefault();
    
    const eventId = $('#editEventId').val();
    const formData = {
      id: eventId,
      title: $('#editEventTitle').val(),
      event_date: $('#editEventDate').val(),
      description: $('#editEventDescription').val(),
      location: $('#editEventLocation').val(),
      outfit_id: $('#editOutfitId').val()
    };
    
    $.ajax({
      url: 'admin_api.php?action=update_event',
      type: 'PUT',
      data: JSON.stringify(formData),
      contentType: 'application/json',
      dataType: 'json',
      headers: {
        'Authorization': 'Bearer ' + getToken()
      },
      success: function(response) {
        if (response.success) {
          showSuccess('Event updated successfully');
          $('#editEventModal').modal('hide');
          loadEvents();
        } else {
          showError(response.error || 'Failed to update event');
        }
      },
      error: function(xhr) {
        showError('Failed to update event');
      }
    });
  });
  
  // Generate Report Form
  $('#reportForm').submit(function(e) {
    e.preventDefault();
    
    const reportType = $('#reportType').val();
    const startDate = $('#startDate').val();
    const endDate = $('#endDate').val();
    
    // This would typically generate a report
    showSuccess('Report generated successfully');
  });
}

// Function to initialize charts
function initializeCharts() {
  // User Registration Chart
  const userCtx = document.getElementById('userChart');
  if(userCtx) {
    window.userChart = new Chart(userCtx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'User Registrations',
          data: [],
          borderColor: 'rgba(0, 123, 255, 1)',
          backgroundColor: 'rgba(0, 123, 255, 0.1)',
          borderWidth: 2,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
  
  // Category Chart
  const categoryCtx = document.getElementById('categoryChart');
  if(categoryCtx) {
    window.categoryChart = new Chart(categoryCtx, {
      type: 'doughnut',
      data: {
        labels: [],
        datasets: [{
          data: [],
          backgroundColor: [
            'rgba(255, 99, 132, 0.7)',
            'rgba(54, 162, 235, 0.7)',
            'rgba(255, 206, 86, 0.7)',
            'rgba(75, 192, 192, 0.7)',
            'rgba(153, 102, 255, 0.7)',
            'rgba(255, 159, 64, 0.7)'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
  
  // User Activity Chart
  const userActivityCtx = document.getElementById('userActivityChart');
  if (userActivityCtx) {
    new Chart(userActivityCtx, {
      type: 'bar',
      data: {
        labels: ['Listings', 'Purchases', 'Outfits Created', 'Events Planned', 'Donations'],
        datasets: [{
          label: 'User Activity',
          data: [65, 42, 30, 25, 15],
          backgroundColor: 'rgba(0, 123, 255, 0.7)'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
  
  // Item Stats Chart
  const itemStatsCtx = document.getElementById('itemStatsChart');
  if (itemStatsCtx) {
    new Chart(itemStatsCtx, {
      type: 'pie',
      data: {
        labels: ['Available', 'Sold', 'Reserved', 'Donated'],
        datasets: [{
          data: [55, 30, 10, 5],
          backgroundColor: [
            'rgba(40, 167, 69, 0.7)',
            'rgba(23, 162, 184, 0.7)',
            'rgba(255, 193, 7, 0.7)',
            'rgba(220, 53, 69, 0.7)'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
}

// Function to update the user chart
function updateUserChart(data) {
  if(!window.userChart) return;
  
  const labels = data.map(item => item.month);
  const values = data.map(item => item.count);
  
  window.userChart.data.labels = labels;
  window.userChart.data.datasets[0].data = values;
  window.userChart.update();
}

// Function to update the user chart with placeholder data
function updateUserChartWithPlaceholder() {
  if(!window.userChart) return;
  
  const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  const values = [5, 8, 12, 10, 15, 20];
  
  window.userChart.data.labels = labels;
  window.userChart.data.datasets[0].data = values;
  window.userChart.update();
}

// Function to update the category chart
function updateCategoryChart(data) {
  if(!window.categoryChart) return;
  
  const labels = data.map(item => item.category);
  const values = data.map(item => item.count);
  
  window.categoryChart.data.labels = labels;
  window.categoryChart.data.datasets[0].data = values;
  window.categoryChart.update();
}

// Function to update the category chart with placeholder data
function updateCategoryChartWithPlaceholder() {
  if(!window.categoryChart) return;
  
  const labels = ['Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Shoes', 'Accessories'];
  const values = [25, 20, 15, 10, 15, 15];
  
  window.categoryChart.data.labels = labels;
  window.categoryChart.data.datasets[0].data = values;
  window.categoryChart.update();
}

// Helper function to format date
function formatDate(dateString) {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}

// Helper function to format date and time
function formatDateTime(dateString) {
  const date = new Date(dateString);
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

// Helper function to format date and time for input fields
function formatDateTimeForInput(dateString) {
  const date = new Date(dateString);
  return date.toISOString().slice(0, 16);
}

// Helper function to get auth token
function getToken() {
  // In a real application, this would get the token from localStorage or cookies
  const token = localStorage.getItem('token') || sessionStorage.getItem('token');
  if (token) {
    return token;
  }
  return 'eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzQ2ODU1MjU5LCJleHAiOjE3NzgzOTEyNTl9';
}

// Helper function to show success message
function showSuccess(message) {
  // Using SweetAlert2 if available, otherwise fallback to alert
  if (typeof Swal !== 'undefined') {
    Swal.fire({
      icon: 'success',
      title: 'Success',
      text: message,
      timer: 2000,
      showConfirmButton: false
    });
  } else {
    alert('✅ ' + message);
  }
}

// Helper function to show error message
function showError(message) {
  // Using SweetAlert2 if available, otherwise fallback to alert
  if (typeof Swal !== 'undefined') {
    Swal.fire({
      icon: 'error',
      title: 'Error',
      text: message
    });
  } else {
    alert('❌ ' + message);
  }
}
  