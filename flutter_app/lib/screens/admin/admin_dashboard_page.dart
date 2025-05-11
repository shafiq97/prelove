import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/admin_api.dart';
import '../../widgets/admin_sidebar.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart';

// Define the DonationCenter model since we don't have one yet
class DonationCenter {
  final int id;
  final String name;
  final String address;
  final String? contactInfo;
  final String? description;
  final String? operatingHours;
  final String? imageUrl;

  const DonationCenter({
    required this.id,
    required this.name,
    required this.address,
    this.contactInfo,
    this.description,
    this.operatingHours,
    this.imageUrl,
  });

  factory DonationCenter.fromJson(Map<String, dynamic> json) {
    return DonationCenter(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      address: json['address'],
      contactInfo: json['contact_info'],
      description: json['description'],
      operatingHours: json['operating_hours'],
      imageUrl: json['image_url'],
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  final int? initialTab;

  const AdminDashboardPage({Key? key, this.initialTab}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isAdmin = false;

  // Data for tabs
  List<User> _users = [];
  List<Item> _items = [];
  List<DonationCenter> _centers = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();

    // Add null safety - ensure widget.initialTab is not null and in valid range
    final initialTabIndex = (widget.initialTab ?? 0).clamp(0, 3);
    print('AdminDashboardPage: Using initialTabIndex: $initialTabIndex');

    _tabController =
        TabController(length: 4, vsync: this, initialIndex: initialTabIndex);

    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update icon colors
      }
    });

    _checkAdminAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if user is admin and load initial data
  Future<void> _checkAdminAndLoadData() async {
    setState(() => _isLoading = true);

    try {
      // Check admin status
      print('AdminDashboardPage: Checking if user is admin...');
      _isAdmin = await AdminApi.isAdmin();
      print('AdminDashboardPage: User is admin: $_isAdmin');

      if (!_isAdmin) {
        // Not an admin, will redirect in build method
        print('AdminDashboardPage: Not an admin, will redirect');
        setState(() => _isLoading = false);
        return;
      }

      // Load data for all tabs
      await Future.wait([
        _loadUsers(),
        _loadItems(),
        _loadDonationCenters(),
        _loadStats(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Load users for the Users tab
  Future<void> _loadUsers() async {
    final usersData = await AdminApi.getUsers();
    if (mounted) {
      setState(() {
        _users = usersData.map((userData) => User.fromJson(userData)).toList();
      });
    }
  }

  // Load items for the Items tab
  Future<void> _loadItems() async {
    final itemsData = await AdminApi.getAllItems();
    if (mounted) {
      setState(() {
        _items = itemsData.map((itemData) => Item.fromJson(itemData)).toList();
      });
    }
  }

  // Load donation centers for the Donations tab
  Future<void> _loadDonationCenters() async {
    final centersData = await AdminApi.getDonationCenters();
    if (mounted) {
      setState(() {
        _centers = centersData
            .map((centerData) => DonationCenter.fromJson(centerData))
            .toList();
      });
    }
  }

  // Load statistics for the Dashboard tab
  Future<void> _loadStats() async {
    final statsData = await AdminApi.getAdminStats();
    if (mounted) {
      setState(() {
        _stats = statsData;
      });
    }
  }

  // Update a user's role
  Future<void> _updateUserRole(int userId, String role) async {
    try {
      final success = await AdminApi.updateUserRole(userId, role);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully')),
        );

        // Refresh the users list
        await _loadUsers();
      } else {
        throw Exception('Failed to update user role');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // View item details
  void _viewItemDetails(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Center(
                  child: Image.network(
                    item.imageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text('Name: ${item.name}'),
              Text('Description: ${item.description}'),
              Text('Price: \$${item.price.toStringAsFixed(2)}'),
              Text('Category: ${item.category}'),
              Text('Condition: ${item.condition}'),
              Text('Seller: ${item.sellerName} (ID: ${item.sellerId})'),
              Text(
                  'Status: ${item.isAvailable ? 'Available' : 'Not Available'}'),
              Text('Created: ${item.createdAt.toString()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Edit item
  void _editItem(Item item) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    String selectedCategory = item.category;
    String selectedCondition = item.condition;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Image.network(
                  item.imageUrl!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Clothing', 'Tops', 'Shoes', 'Accessories', 'Other']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ['New', 'Like New', 'Very Good', 'Good', 'Used', 'Fair']
                    .map((condition) => DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCondition = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Input validation
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  throw Exception('Name and description are required');
                }

                double? price = double.tryParse(priceController.text);
                if (price == null || price < 0) {
                  throw Exception('Please enter a valid price');
                }

                final updatedItem = {
                  'id': item.id,
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': price,
                  'category': selectedCategory,
                  'condition':
                      selectedCondition, // Use 'condition' to match the database column name
                };

                final response = await http.put(
                  Uri.parse(
                      '${AdminApi.baseUrl}/api/v1/items_api.php/${item.id}'),
                  headers: {
                    ...AdminApi.jsonHeaders,
                    'Authorization':
                        'Bearer ${(await SharedPreferences.getInstance()).getString('auth_token')}'
                  },
                  body: json.encode(updatedItem),
                );

                final responseData = json.decode(response.body);

                if (response.statusCode == 200 &&
                    responseData['success'] == true) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Item updated successfully')),
                    );
                    _loadItems(); // Refresh the items list
                  }
                } else {
                  throw Exception(
                      responseData['error'] ?? 'Failed to update item');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit donation center
  void _editDonationCenter(DonationCenter center) {
    final nameController = TextEditingController(text: center.name);
    final addressController = TextEditingController(text: center.address);
    final contactInfoController =
        TextEditingController(text: center.contactInfo ?? '');
    final descriptionController =
        TextEditingController(text: center.description ?? '');
    final operatingHoursController =
        TextEditingController(text: center.operatingHours ?? '');
    final imageUrlController =
        TextEditingController(text: center.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Donation Center'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (center.imageUrl != null && center.imageUrl!.isNotEmpty)
                Image.network(
                  center.imageUrl!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: contactInfoController,
                decoration: const InputDecoration(labelText: 'Contact Info'),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: operatingHoursController,
                decoration: const InputDecoration(labelText: 'Operating Hours'),
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Input validation
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  throw Exception('Name and address are required');
                }

                final updatedCenter = {
                  'id': center.id,
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'contact_info': contactInfoController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'operating_hours': operatingHoursController.text.trim(),
                  'image_url': imageUrlController.text.trim(),
                };

                final success =
                    await AdminApi.updateDonationCenter(updatedCenter);

                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Donation center updated successfully')),
                    );
                    _loadDonationCenters(); // Refresh the list
                  }
                } else {
                  throw Exception('Failed to update donation center');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add new donation center
  void _addDonationCenter() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final contactInfoController = TextEditingController();
    final descriptionController = TextEditingController();
    final operatingHoursController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Donation Center',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactInfoController,
                  decoration: const InputDecoration(labelText: 'Contact Info'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: operatingHoursController,
                  decoration: const InputDecoration(
                      labelText: 'Operating Hours (e.g., Mon-Fri: 9am-5pm)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Input validation
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  throw Exception('Name and address are required');
                }

                final newCenter = {
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'contact_info': contactInfoController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'operating_hours': operatingHoursController.text.trim(),
                  'image_url': imageUrlController.text.trim(),
                };

                final success = await AdminApi.addDonationCenter(newCenter);

                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Donation center added successfully')),
                    );
                    _loadDonationCenters(); // Refresh the list
                  }
                } else {
                  throw Exception('Failed to add donation center');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // View donations for a center
  Future<void> _viewDonations(DonationCenter center) async {
    setState(() => _isLoading = true);

    try {
      final donations = await AdminApi.getDonations();

      // Filter donations for the selected center
      final centerDonations = donations
          .where((donation) =>
              donation['center_id'] == center.id ||
              donation['center_name'] == center.name)
          .toList();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (centerDonations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No donations found for ${center.name}')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Donations for ${center.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: centerDonations.length,
              itemBuilder: (context, index) {
                final donation = centerDonations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title:
                        Text('Donor: ${donation['donor_name'] ?? 'Anonymous'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Date: ${donation['donation_date'] ?? donation['scheduled_date'] ?? 'N/A'}'),
                        Text('Status: ${donation['status'] ?? 'N/A'}'),
                        if (donation['items'] != null)
                          Text('Items: ${donation['items']}'),
                        if (donation['notes'] != null &&
                            donation['notes'].isNotEmpty)
                          Text('Notes: ${donation['notes']}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Redirect if not admin
    if (!_isLoading && !_isAdmin) {
      print('AdminDashboardPage build: Not admin, redirecting to login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('AdminDashboardPage: Performing redirect to login');
        // Use context.go instead of Navigator to work with GoRouter
        context.go('/login', extra: {'message': 'Admin access required'});
      });

      return const Scaffold(
        body: Center(child: Text('Redirecting...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Make selected tab text white
          unselectedLabelColor:
              Colors.white70, // Slightly dimmer for unselected tabs
          indicatorColor: Colors.white, // White indicator line
          indicatorWeight: 3.0, // Make indicator more visible
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold), // Bold text for selected tab
          tabs: [
            Tab(
              icon: Icon(
                Icons.dashboard,
                color:
                    _tabController.index == 0 ? Colors.white : Colors.white70,
              ),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(
                Icons.people,
                color:
                    _tabController.index == 1 ? Colors.white : Colors.white70,
              ),
              text: 'Users',
            ),
            Tab(
              icon: Icon(
                Icons.inventory,
                color:
                    _tabController.index == 2 ? Colors.white : Colors.white70,
              ),
              text: 'Items',
            ),
            Tab(
              icon: Icon(
                Icons.volunteer_activism,
                color:
                    _tabController.index == 3 ? Colors.white : Colors.white70,
              ),
              text: 'Donations',
            ),
          ],
        ),
      ),
      drawer: const AdminSidebar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildItemsTab(),
                _buildDonationsTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Build the dashboard statistics tab
  Widget _buildDashboardTab() {
    if (_stats.isEmpty) {
      return const Center(child: Text('No statistics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stat cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Users', _stats['user_count'].toString(),
                  Icons.people, Colors.blue),
              _buildStatCard('Items', _stats['item_count'].toString(),
                  Icons.inventory, Colors.green),
              _buildStatCard('Outfits', _stats['outfit_count'].toString(),
                  Icons.checkroom, Colors.purple),
              _buildStatCard('Events', _stats['event_count'].toString(),
                  Icons.event, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  // Build a stat card widget
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the users management tab
  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(user.username.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.username),
            subtitle: Text(user.email),
            trailing: DropdownButton<String>(
              value: user.role ?? 'user',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateUserRole(user.id, newValue);
                }
              },
              items: <String>['user', 'admin']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Build the items management tab
  Widget _buildItemsTab() {
    if (_items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              Expanded(
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child:
                              Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),
              ),

              // Item details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: \$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${item.category}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _viewItemDetails(item),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => _editItem(item),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build the donations tab
  Widget _buildDonationsTab() {
    if (_centers.isEmpty) {
      return const Center(child: Text('No donation centers found'));
    }

    return ListView.builder(
      itemCount: _centers.length,
      itemBuilder: (context, index) {
        final center = _centers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center image
              if (center.imageUrl != null && center.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    center.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              // Center details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            center.address,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    if (center.contactInfo != null &&
                        center.contactInfo!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            center.contactInfo!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _editDonationCenter(center);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _viewDonations(center);
                          },
                          icon: const Icon(Icons.view_list),
                          label: const Text('View Donations'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build the floating action button based on the current tab
  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: // Users tab
        return FloatingActionButton(
          onPressed: () {
            // Show add user dialog
          },
          child: const Icon(Icons.person_add),
        );
      case 2: // Items tab
        return FloatingActionButton(
          onPressed: () {
            // Show add item dialog
          },
          child: const Icon(Icons.add_shopping_cart),
        );
      case 3: // Donations tab
        return FloatingActionButton(
          onPressed: () {
            _addDonationCenter();
          },
          child: const Icon(Icons.add_location),
        );
      default:
        return null;
    }
  }
}
