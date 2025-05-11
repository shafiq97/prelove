import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/admin_api.dart';
import '../models/item_model.dart';
import '../config/theme_config.dart';
import '../widgets/app_bottom_navbar.dart';
import '../services/navigation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Item> _items = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMoreItems = true;
  String? _selectedCategory;
  bool _isAdmin = false;

  final List<String> categories = [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _checkAdminStatus();
  }

  // Check if the current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      // First check if token exists
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Home screen: Token from SharedPreferences: $token');

      final isAdmin = await AdminApi.isAdmin();
      print('Home screen: User is admin check result: $isAdmin');

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load items from the API
  Future<void> _loadItems({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _items = [];
        _currentPage = 1;
        _hasMoreItems = true;
      }
      _errorMessage = '';
    });

    try {
      final category = _selectedCategory == 'All' || _selectedCategory == null
          ? null
          : _selectedCategory;

      final response = await _apiService.getItems(
        page: _currentPage,
        category: category,
      );

      if (response['success']) {
        final newItems = (response['items'] as List)
            .map((item) => Item.fromJson(item))
            .toList();

        setState(() {
          if (refresh) {
            _items = newItems;
          } else {
            _items.addAll(newItems);
          }

          _hasMoreItems = newItems.length >= 10; // Assuming 10 items per page
          _currentPage++;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load items';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Search for items
  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadItems(refresh: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _items = [];
      _errorMessage = '';
    });

    try {
      final response = await _apiService.searchItems(query);

      if (response['success']) {
        final searchResults = (response['items'] as List)
            .map((item) => Item.fromJson(item))
            .toList();

        setState(() {
          _items = searchResults;
          _hasMoreItems = false; // Disable pagination for search results
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Search failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access current user
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preloved Closet'),
        actions: [
          // Test button for admin dashboard
          IconButton(
            icon: const Icon(Icons.admin_panel_settings,
                color: Colors.purpleAccent),
            onPressed: () {
              print('Home screen: Direct admin test button pressed');
              context.go('/admin');
            },
          ),
          // Admin dashboard button - only shown for admin users
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
              onPressed: () {
                print('Home screen: Admin button pressed');
                context.go('/admin');
              },
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => NavigationService.navigateToCart(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => NavigationService.navigateToProfile(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.fullName ?? user?.username ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Item'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToAddItem(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checkroom),
              title: const Text('My Closet'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToPlanner(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Schedule'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToSchedule(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Donation Centers'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToDonationCenters(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Orders History'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToHistory(context);
              },
            ),
            // Admin Dashboard menu item - only shown for admin users
            if (_isAdmin)
              ListTile(
                leading:
                    const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Admin Dashboard',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await authService.logout();
                if (context.mounted) NavigationService.navigateToLogin(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _searchItems(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Show filter dialog
                  },
                ),
              ],
            ),
          ),

          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category ||
                    (category == 'All' && _selectedCategory == null);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? (category == 'All' ? null : category)
                            : null;
                      });
                      _loadItems(refresh: true);
                    },
                  ),
                );
              },
            ),
          ),

          // Error message if any
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),

          // Items grid
          Expanded(
            child: _isLoading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text('No items found'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadItems(refresh: true),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                !_isLoading &&
                                _hasMoreItems) {
                              _loadItems();
                            }
                            return false;
                          },
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _items.length + (_hasMoreItems ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final item = _items[index];
                              return ItemCard(
                                item: item,
                                onTap: () {
                                  context.go('/home/items/${item.id}');
                                },
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationService.navigateToAddItem(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
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
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.condition,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMediumColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
