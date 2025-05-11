import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_api.dart';

class AdminSidebar extends StatefulWidget {
  const AdminSidebar({Key? key}) : super(key: key);

  @override
  _AdminSidebarState createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  String _username = '';
  String _email = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Load user info from shared preferences
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final email = prefs.getString('email') ?? '';
      final isAdmin = await AdminApi.isAdmin();

      setState(() {
        _username = username;
        _email = email;
        _isAdmin = isAdmin;
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // Handle logout
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('userId');

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error during logout: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(_username),
            accountEmail: Text(_email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                style: TextStyle(
                    fontSize: 40.0, color: Theme.of(context).primaryColor),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/admin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Item Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/items');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Event Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text('Donation Centers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/donations');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: _logout,
          ),
          if (!_isAdmin)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This area is restricted to administrators.',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
