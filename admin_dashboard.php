<?php
require_once 'admin_auth.php';
requireAdmin(); // Redirect if not admin
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard - Preloved Closet</title>
  <link rel="stylesheet" href="css/admin_style.css">
  <!-- Bootstrap CSS -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
  <div class="container-fluid">
    <div class="row">
      <!-- Sidebar -->
      <nav id="sidebar" class="col-md-3 col-lg-2 d-md-block bg-dark sidebar collapse">
        <div class="position-sticky pt-3">
          <div class="text-center mb-4">
            <img src="preloved logo.jpg" alt="Preloved Closet Logo" class="img-fluid rounded-circle" style="max-width: 100px;">
            <h4 class="text-white mt-2">Admin Panel</h4>
          </div>
          <ul class="nav flex-column">
            <li class="nav-item">
              <a class="nav-link active" href="#dashboard" data-bs-toggle="tab">
                <i class="fas fa-tachometer-alt me-2"></i> Dashboard
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#users" data-bs-toggle="tab">
                <i class="fas fa-users me-2"></i> Users
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#items" data-bs-toggle="tab">
                <i class="fas fa-tshirt me-2"></i> Items
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#add-item" data-bs-toggle="tab">
                <i class="fas fa-plus-circle me-2"></i> Add Item
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#events" data-bs-toggle="tab">
                <i class="fas fa-calendar-alt me-2"></i> Events
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#add-event" data-bs-toggle="tab">
                <i class="fas fa-plus-circle me-2"></i> Add Event
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#donations" data-bs-toggle="tab">
                <i class="fas fa-hand-holding-heart me-2"></i> Donations
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#reports" data-bs-toggle="tab">
                <i class="fas fa-chart-bar me-2"></i> Reports
              </a>
            </li>
            <li class="nav-item mt-5">
              <a class="nav-link text-danger" href="logout.php">
                <i class="fas fa-sign-out-alt me-2"></i> Logout
              </a>
            </li>
          </ul>
        </div>
      </nav>

      <!-- Main content -->
      <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4">
        <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
          <h1 class="h2">Admin Dashboard</h1>
          <div class="btn-toolbar mb-2 mb-md-0">
            <div class="btn-group me-2">
              <button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
              <button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
            </div>
          </div>
        </div>

        <!-- Tab content -->
        <div class="tab-content">
          <!-- Dashboard -->
          <div class="tab-pane fade show active" id="dashboard">
            <div class="row mt-4">
              <div class="col-md-3 mb-4">
                <div class="card bg-primary text-white h-100">
                  <div class="card-body py-5">
                    <div class="d-flex justify-content-between align-items-center">
                      <h2 id="userCount">0</h2>
                      <i class="fas fa-users fa-3x"></i>
                    </div>
                    <p class="mb-0">Total Users</p>
                  </div>
                </div>
              </div>
              <div class="col-md-3 mb-4">
                <div class="card bg-success text-white h-100">
                  <div class="card-body py-5">
                    <div class="d-flex justify-content-between align-items-center">
                      <h2 id="itemCount">0</h2>
                      <i class="fas fa-tshirt fa-3x"></i>
                    </div>
                    <p class="mb-0">Total Items</p>
                  </div>
                </div>
              </div>
              <div class="col-md-3 mb-4">
                <div class="card bg-warning text-white h-100">
                  <div class="card-body py-5">
                    <div class="d-flex justify-content-between align-items-center">
                      <h2 id="eventCount">0</h2>
                      <i class="fas fa-calendar-alt fa-3x"></i>
                    </div>
                    <p class="mb-0">Events</p>
                  </div>
                </div>
              </div>
              <div class="col-md-3 mb-4">
                <div class="card bg-danger text-white h-100">
                  <div class="card-body py-5">
                    <div class="d-flex justify-content-between align-items-center">
                      <h2 id="donationCount">0</h2>
                      <i class="fas fa-hand-holding-heart fa-3x"></i>
                    </div>
                    <p class="mb-0">Donations</p>
                  </div>
                </div>
              </div>
            </div>

            <div class="row mt-4">
              <div class="col-md-6">
                <div class="card mb-4">
                  <div class="card-header">
                    <i class="fas fa-chart-area me-1"></i>
                    User Registration Trend
                  </div>
                  <div class="card-body">
                    <canvas id="userChart" width="100%" height="40"></canvas>
                  </div>
                </div>
              </div>
              <div class="col-md-6">
                <div class="card mb-4">
                  <div class="card-header">
                    <i class="fas fa-chart-bar me-1"></i>
                    Item Categories
                  </div>
                  <div class="card-body">
                    <canvas id="categoryChart" width="100%" height="40"></canvas>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Users Tab -->
          <div class="tab-pane fade" id="users">
            <h2 class="mt-4">User Management</h2>
            <div class="table-responsive mt-3">
              <table class="table table-striped table-sm" id="usersTable">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Username</th>
                    <th>Email</th>
                    <th>Full Name</th>
                    <th>Role</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Will be populated with AJAX -->
                </tbody>
              </table>
            </div>
          </div>

          <!-- Items Tab -->
          <div class="tab-pane fade" id="items">
            <h2 class="mt-4">Item Management</h2>
            <div class="d-flex justify-content-between mb-3">
              <div class="input-group w-50">
                <input type="text" class="form-control" placeholder="Search items..." id="itemSearch">
                <button class="btn btn-outline-secondary" type="button">
                  <i class="fas fa-search"></i>
                </button>
              </div>
              <button class="btn btn-primary" onclick="$('#add-item-tab').click()">
                <i class="fas fa-plus-circle"></i> Add New Item
              </button>
            </div>
            <div class="table-responsive">
              <table class="table table-striped table-sm" id="itemsTable">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Image</th>
                    <th>Name</th>
                    <th>Category</th>
                    <th>Price</th>
                    <th>Condition</th>
                    <th>Seller</th>
                    <th>Available</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Will be populated with AJAX -->
                </tbody>
              </table>
            </div>
          </div>

          <!-- Add Item Tab -->
          <div class="tab-pane fade" id="add-item">
            <h2 class="mt-4">Add New Item</h2>
            <div class="card mt-3">
              <div class="card-body">
                <form id="addItemForm" enctype="multipart/form-data">
                  <div class="row">
                    <div class="col-md-6 mb-3">
                      <label for="itemName" class="form-label">Item Name</label>
                      <input type="text" class="form-control" id="itemName" name="name" required>
                    </div>
                    <div class="col-md-6 mb-3">
                      <label for="itemCategory" class="form-label">Category</label>
                      <select class="form-select" id="itemCategory" name="category" required>
                        <option value="">Select category</option>
                        <option value="Tops">Tops</option>
                        <option value="Bottoms">Bottoms</option>
                        <option value="Dresses">Dresses</option>
                        <option value="Outerwear">Outerwear</option>
                        <option value="Shoes">Shoes</option>
                        <option value="Accessories">Accessories</option>
                      </select>
                    </div>
                  </div>

                  <div class="row">
                    <div class="col-md-6 mb-3">
                      <label for="itemPrice" class="form-label">Price</label>
                      <div class="input-group">
                        <span class="input-group-text">$</span>
                        <input type="number" class="form-control" id="itemPrice" name="price" step="0.01" min="0" required>
                      </div>
                    </div>
                    <div class="col-md-6 mb-3">
                      <label for="itemCondition" class="form-label">Condition</label>
                      <select class="form-select" id="itemCondition" name="condition" required>
                        <option value="">Select condition</option>
                        <option value="New">New</option>
                        <option value="Like New">Like New</option>
                        <option value="Good">Good</option>
                        <option value="Fair">Fair</option>
                      </select>
                    </div>
                  </div>

                  <div class="mb-3">
                    <label for="itemDescription" class="form-label">Description</label>
                    <textarea class="form-control" id="itemDescription" name="description" rows="3" required></textarea>
                  </div>

                  <div class="mb-3">
                    <label for="itemImage" class="form-label">Image</label>
                    <input type="file" class="form-control" id="itemImage" name="image" accept="image/*" required>
                    <div class="form-text">Upload an image of the item (max 5MB).</div>
                  </div>

                  <div class="mb-3">
                    <label for="sellerId" class="form-label">Seller</label>
                    <select class="form-select" id="sellerId" name="seller_id" required>
                      <!-- Will be populated with AJAX -->
                    </select>
                  </div>

                  <div class="form-check mb-3">
                    <input class="form-check-input" type="checkbox" id="isAvailable" name="is_available" checked>
                    <label class="form-check-label" for="isAvailable">
                      Item is available
                    </label>
                  </div>

                  <button type="submit" class="btn btn-primary">
                    <i class="fas fa-plus-circle"></i> Add Item
                  </button>
                </form>
              </div>
            </div>
          </div>

          <!-- Events Tab -->
          <div class="tab-pane fade" id="events">
            <h2 class="mt-4">Event Management</h2>
            <div class="d-flex justify-content-between mb-3">
              <div class="input-group w-50">
                <input type="text" class="form-control" placeholder="Search events..." id="eventSearch">
                <button class="btn btn-outline-secondary" type="button">
                  <i class="fas fa-search"></i>
                </button>
              </div>
              <button class="btn btn-primary" onclick="$('#add-event-tab').click()">
                <i class="fas fa-plus-circle"></i> Add New Event
              </button>
            </div>
            <div class="table-responsive">
              <table class="table table-striped table-sm" id="eventsTable">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Title</th>
                    <th>Date</th>
                    <th>Location</th>
                    <th>Outfit</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Will be populated with AJAX -->
                </tbody>
              </table>
            </div>
          </div>

          <!-- Add Event Tab -->
          <div class="tab-pane fade" id="add-event">
            <h2 class="mt-4">Add New Event</h2>
            <div class="card mt-3">
              <div class="card-body">
                <form id="addEventForm">
                  <div class="row">
                    <div class="col-md-6 mb-3">
                      <label for="eventTitle" class="form-label">Event Title</label>
                      <input type="text" class="form-control" id="eventTitle" name="title" required>
                    </div>
                    <div class="col-md-6 mb-3">
                      <label for="eventDate" class="form-label">Event Date</label>
                      <input type="datetime-local" class="form-control" id="eventDate" name="event_date" required>
                    </div>
                  </div>

                  <div class="mb-3">
                    <label for="eventDescription" class="form-label">Description</label>
                    <textarea class="form-control" id="eventDescription" name="description" rows="3"></textarea>
                  </div>

                  <div class="mb-3">
                    <label for="eventLocation" class="form-label">Location</label>
                    <input type="text" class="form-control" id="eventLocation" name="location">
                  </div>

                  <div class="mb-3">
                    <label for="outfitId" class="form-label">Associated Outfit (Optional)</label>
                    <select class="form-select" id="outfitId" name="outfit_id">
                      <option value="">Select an outfit</option>
                      <!-- Will be populated with AJAX -->
                    </select>
                  </div>

                  <div class="mb-3">
                    <label for="userId" class="form-label">User</label>
                    <select class="form-select" id="userId" name="user_id" required>
                      <!-- Will be populated with AJAX -->
                    </select>
                  </div>

                  <button type="submit" class="btn btn-primary">
                    <i class="fas fa-plus-circle"></i> Add Event
                  </button>
                </form>
              </div>
            </div>
          </div>

          <!-- Donations Tab -->
          <div class="tab-pane fade" id="donations">
            <h2 class="mt-4">Donation Management</h2>
            <div class="table-responsive mt-3">
              <table class="table table-striped table-sm" id="donationsTable">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Donor</th>
                    <th>Center</th>
                    <th>Items</th>
                    <th>Date</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Will be populated with AJAX -->
                </tbody>
              </table>
            </div>
          </div>

          <!-- Reports Tab -->
          <div class="tab-pane fade" id="reports">
            <h2 class="mt-4">Reports</h2>
            <div class="row mt-3">
              <div class="col-md-6 mb-4">
                <div class="card">
                  <div class="card-header">
                    <h5 class="card-title mb-0">User Activity</h5>
                  </div>
                  <div class="card-body">
                    <canvas id="userActivityChart"></canvas>
                  </div>
                </div>
              </div>
              <div class="col-md-6 mb-4">
                <div class="card">
                  <div class="card-header">
                    <h5 class="card-title mb-0">Item Statistics</h5>
                  </div>
                  <div class="card-body">
                    <canvas id="itemStatsChart"></canvas>
                  </div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-12">
                <div class="card">
                  <div class="card-header">
                    <h5 class="card-title mb-0">Generate Report</h5>
                  </div>
                  <div class="card-body">
                    <form id="reportForm">
                      <div class="row">
                        <div class="col-md-4">
                          <div class="mb-3">
                            <label class="form-label">Report Type</label>
                            <select class="form-select" id="reportType">
                              <option value="users">User Growth</option>
                              <option value="items">Item Listings</option>
                              <option value="donations">Donations</option>
                              <option value="categories">Categories</option>
                            </select>
                          </div>
                        </div>
                        <div class="col-md-4">
                          <div class="mb-3">
                            <label class="form-label">Start Date</label>
                            <input type="date" class="form-control" id="startDate">
                          </div>
                        </div>
                        <div class="col-md-4">
                          <div class="mb-3">
                            <label class="form-label">End Date</label>
                            <input type="date" class="form-control" id="endDate">
                          </div>
                        </div>
                      </div>
                      <button type="submit" class="btn btn-primary">Generate Report</button>
                      <button type="button" class="btn btn-outline-secondary" id="exportPDF">Export as PDF</button>
                      <button type="button" class="btn btn-outline-secondary" id="exportCSV">Export as CSV</button>
                    </form>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>

  <!-- Footer -->
  <footer class="footer mt-auto py-3 bg-light">
    <div class="container">
      <span class="text-muted">© 2025 Preloved Closet - Admin Dashboard</span>
    </div>
  </footer>

  <!-- Bootstrap, jQuery, Chart.js -->
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script src="js/admin_script.js"></script>
</body>
</html>
