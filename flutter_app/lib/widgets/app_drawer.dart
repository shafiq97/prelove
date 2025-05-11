import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex; // 0 = Home, 1 = Closet, 2 = History etc.

  const AppDrawer({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Drawer(
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
          _buildTile(context, Icons.home, 'Home', 0, () {
            NavigationService.navigateToHome(context);
          }),
          _buildTile(context, Icons.add_box, 'Add Item', -1, () {
            NavigationService.navigateToAddItem(context);
          }),
          _buildTile(context, Icons.checkroom, 'My Closet', 1, () {
            NavigationService.navigateToPlanner(context);
          }),
          _buildTile(context, Icons.calendar_month, 'Schedule', -1, () {
            NavigationService.navigateToSchedule(context);
          }),
          _buildTile(context, Icons.volunteer_activism, 'Donation Centers', -1,
              () {
            NavigationService.navigateToDonationCenters(context);
          }),
          _buildTile(context, Icons.history, 'Orders History', 2, () {
            NavigationService.navigateToHistory(context);
          }),
          const Divider(),
          _buildTile(context, Icons.settings, 'Settings', -1, () {
            NavigationService.navigateToSettings(context);
          }),
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
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title,
      int index, VoidCallback onTap) {
    final selected = currentIndex == index;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        if (!selected) onTap();
      },
    );
  }
}
