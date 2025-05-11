import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _history = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistory();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _apiService.getOrderHistory();
      if (response['success']) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(response['history']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Format amount to always show 2 decimal places
  String _formatAmount(dynamic amount) {
    try {
      // If amount is already a string, try to parse it as double
      if (amount is String) {
        // Remove any non-numeric characters except for decimal point
        final cleanedAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
        // Try parsing as double
        final parsedAmount = double.tryParse(cleanedAmount);
        if (parsedAmount != null) {
          return parsedAmount.toStringAsFixed(2);
        } else {
          return amount; // Return original string if parsing fails
        }
      }
      // If amount is already a number (double or int)
      else if (amount is double) {
        return amount.toStringAsFixed(2);
      } else if (amount is int) {
        return amount.toDouble().toStringAsFixed(2);
      }
      // Default fallback
      return amount.toString();
    } catch (e) {
      print('Error formatting amount: $e');
      return '0.00'; // Safe fallback
    }
  }

  List<Map<String, dynamic>> _getFilteredHistory(String category) {
    return _history.where((item) {
      final matchesCategory = category == 'all' || item['category'] == category;
      final matchesSearch = _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(_searchQuery) ||
          item['status'].toString().toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    IconData categoryIcon;
    Color categoryColor;

    switch (item['category']) {
      case 'purchase':
        categoryIcon = Icons.shopping_bag;
        categoryColor = Colors.blue;
        break;
      case 'sale':
        categoryIcon = Icons.sell;
        categoryColor = Colors.green;
        break;
      case 'donation':
        categoryIcon = Icons.volunteer_activism;
        categoryColor = Colors.orange;
        break;
      default:
        categoryIcon = Icons.category;
        categoryColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withOpacity(0.1),
          child: Icon(categoryIcon, color: categoryColor),
        ),
        title: Text(
          item['title'] ?? 'Untitled Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${item['status'] ?? 'Unknown'}',
              style: TextStyle(
                color: item['status'] == 'completed'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            Text(
              'Date: ${item['date'] ?? 'Unknown date'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item['amount'] != null)
              Text(
                'Amount: RM${_formatAmount(item['amount'])}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
        bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Purchases'),
            Tab(text: 'Sales'),
            Tab(text: 'Donations'),
          ],
        ),
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
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToHome(context);
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
              selected: true,
              onTap: () {
                Navigator.pop(context);
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
                if (context.mounted) {
                  NavigationService.navigateToLogin(context);
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  children: _getFilteredHistory('all')
                      .map((item) => _buildHistoryItem(item))
                      .toList(),
                ),
                ListView(
                  children: _getFilteredHistory('purchase')
                      .map((item) => _buildHistoryItem(item))
                      .toList(),
                ),
                ListView(
                  children: _getFilteredHistory('sale')
                      .map((item) => _buildHistoryItem(item))
                      .toList(),
                ),
                ListView(
                  children: _getFilteredHistory('donation')
                      .map((item) => _buildHistoryItem(item))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}
