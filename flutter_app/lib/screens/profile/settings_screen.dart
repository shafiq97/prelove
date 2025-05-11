import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'en';
  bool _privacy = false;
  bool _showSoldItems = true;
  bool _showDonatedItems = true;
  bool _outfitSuggestions = true;
  bool _saleNotifications = true;
  bool _donationReminders = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.getUserSettings();

        if (response['success']) {
          setState(() {
            _darkMode = response['settings']['dark_mode'] ?? false;
            _notifications = response['settings']['notifications'] ?? true;
            _language = response['settings']['language'] ?? 'en';
            _privacy = response['settings']['privacy'] ?? false;
            _showSoldItems = response['settings']['show_sold_items'] ?? true;
            _showDonatedItems =
                response['settings']['show_donated_items'] ?? true;
            _outfitSuggestions =
                response['settings']['outfit_suggestions'] ?? true;
            _saleNotifications =
                response['settings']['sale_notifications'] ?? true;
            _donationReminders =
                response['settings']['donation_reminders'] ?? true;
          });
        }
      } catch (e) {
        // Silently ignore 401 and other errors - don't show any error messages
        print('Settings loading error (ignored): $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.updateUserSettings(
          darkMode: _darkMode,
          notifications: _notifications,
          language: _language,
          privacy: _privacy,
          showSoldItems: _showSoldItems,
          showDonatedItems: _showDonatedItems,
          outfitSuggestions: _outfitSuggestions,
          saleNotifications: _saleNotifications,
          donationReminders: _donationReminders,
        );

        if (mounted && response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings updated successfully')),
          );
        }
      } catch (e) {
        // Silently ignore 401 and other errors
        print('Settings save error (ignored): $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '👤 Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Edit Profile'),
                    leading: const Icon(Icons.person),
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    leading: const Icon(Icons.lock),
                    onTap: () {
                      // Implement password change
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Closet Preferences
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '🧺 Closet Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show Sold Items'),
                    value: _showSoldItems,
                    onChanged: (value) =>
                        setState(() => _showSoldItems = value),
                  ),
                  SwitchListTile(
                    title: const Text('Show Donated Items'),
                    value: _showDonatedItems,
                    onChanged: (value) =>
                        setState(() => _showDonatedItems = value),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Outfit Suggestions'),
                    value: _outfitSuggestions,
                    onChanged: (value) =>
                        setState(() => _outfitSuggestions = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '🔔 Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                  if (_notifications) ...[
                    SwitchListTile(
                      title: const Text('Sale Updates'),
                      value: _saleNotifications,
                      onChanged: (value) =>
                          setState(() => _saleNotifications = value),
                    ),
                    SwitchListTile(
                      title: const Text('Donation Reminders'),
                      value: _donationReminders,
                      onChanged: (value) =>
                          setState(() => _donationReminders = value),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appearance Settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '🎨 Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                  ListTile(
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: _language,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _language = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '🔒 Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Private Profile'),
                    subtitle: const Text('Only followers can see your closet'),
                    value: _privacy,
                    onChanged: (value) => setState(() => _privacy = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Other Settings
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '⚙️ Other',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Terms & Conditions'),
                    leading: const Icon(Icons.description),
                    onTap: () {
                      NavigationService.navigateToTerms(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip),
                    onTap: () {
                      NavigationService.navigateToPrivacy(context);
                    },
                  ),
                  ListTile(
                    title: const Text('About'),
                    leading: const Icon(Icons.info),
                    onTap: () {
                      NavigationService.navigateToAbout(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}
