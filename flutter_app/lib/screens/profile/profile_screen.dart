import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _stats = {
    'selling': 0,
    'donated': 0,
    'purchased': 0,
  };

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _apiService.getUserProfile();
      if (response['success']) {
        final user =
            Provider.of<AuthService>(context, listen: false).currentUser!;
        _fullNameController.text = user.fullName ?? '';
        _phoneController.text = user.phone ?? '';
        _addressController.text = user.address ?? '';

        setState(() {
          _stats = {
            'selling': response['stats']['selling'] ?? 0,
            'donated': response['stats']['donated'] ?? 0,
            'purchased': response['stats']['purchased'] ?? 0,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load profile';
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

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _newProfileImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Debug token first
      final tokenTest = await _apiService.testAuthentication();
      if (!tokenTest['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Authentication issue: ${tokenTest['error'] ?? "Unknown auth error"}')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final response = await _apiService.updateUserProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        profileImage: _newProfileImage?.path,
      );

      if (mounted) {
        if (response['success']) {
          final authService = Provider.of<AuthService>(context, listen: false);
          authService.updateCurrentUser(User.fromJson(response['user']));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() => _isLoading = false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['error'] ?? 'Failed to update profile')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    // Test token first
    try {
      final response = await _apiService.testToken();
      if (!response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: ${response['error']}')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing authentication: $e')),
      );
      return;
    }

    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    bool _isLoading = false;
    String _errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Form(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      // Validate inputs
                      if (_currentPasswordController.text.isEmpty ||
                          _newPasswordController.text.isEmpty ||
                          _confirmPasswordController.text.isEmpty) {
                        setState(() {
                          _errorMessage = 'All fields are required';
                        });
                        return;
                      }

                      if (_newPasswordController.text.length < 8) {
                        setState(() {
                          _errorMessage =
                              'New password must be at least 8 characters';
                        });
                        return;
                      }

                      if (_newPasswordController.text !=
                          _confirmPasswordController.text) {
                        setState(() {
                          _errorMessage = 'Passwords do not match';
                        });
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                        _errorMessage = '';
                      });

                      try {
                        final response = await _apiService.changePassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                        );

                        if (response['success']) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password changed successfully')),
                          );
                        } else {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = response['error'] ??
                                'Failed to change password';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                          _errorMessage = e.toString();
                        });
                      }
                    },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _debugTokenVerification() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _apiService.debugToken();

      setState(() {
        _isLoading = false;
      });

      // Show response in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(response['success'] ? 'Token Verified' : 'Token Error'),
          content: SingleChildScrollView(
            child: Text(
              response['success']
                  ? 'Token data: ${response['token_data']}'
                  : 'Error: ${response['error']}',
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
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error debugging token: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
        bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugTokenVerification,
            tooltip: 'Debug Token',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : (user?.profileImage != null
                                ? NetworkImage(user!.profileImage!)
                                : null) as ImageProvider?,
                        child: user?.profileImage == null &&
                                _newProfileImage == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                    icon: Icons.shopping_bag,
                    title: 'Selling',
                    value: _stats['selling'].toString()),
                _StatCard(
                    icon: Icons.volunteer_activism,
                    title: 'Donated',
                    value: _stats['donated'].toString()),
                _StatCard(
                    icon: Icons.shopping_cart,
                    title: 'Purchased',
                    value: _stats['purchased'].toString()),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Edit Profile',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Debug authentication button
                      // ElevatedButton.icon(
                      //   icon: const Icon(Icons.health_and_safety),
                      //   label: const Text('Test Auth'),
                      //   onPressed: () async {
                      //     final result = await _apiService.testAuthentication();
                      //     if (result['success']) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //             content: Text(
                      //                 'Authentication working: ${result['user']['username']}')),
                      //       );
                      //     } else {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //             content:
                      //                 Text('Auth failed: ${result['error']}')),
                      //       );
                      //     }
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue.shade800,
                      //     foregroundColor: Colors.white,
                      //   ),
                      // ),
                      // const SizedBox(height: 8),

                      // Debug profile API button
                      // ElevatedButton.icon(
                      //   icon: const Icon(Icons.engineering),
                      //   label: const Text('Debug Profile API'),
                      //   onPressed: () async {
                      //     final result = await _apiService.debugProfile();
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) => AlertDialog(
                      //         title: Text(result['success']
                      //             ? 'Profile Debug OK'
                      //             : 'Profile Debug Error'),
                      //         content: SingleChildScrollView(
                      //           child: Text(
                      //             result['success']
                      //                 ? 'Token data: ${result['token_data']}'
                      //                 : 'Error: ${result['error']}',
                      //           ),
                      //         ),
                      //         actions: [
                      //           TextButton(
                      //             onPressed: () => Navigator.pop(context),
                      //             child: const Text('Close'),
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.green.shade800,
                      //     foregroundColor: Colors.white,
                      //   ),
                      // ),
                      // const SizedBox(height: 16),

                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your phone number'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your address'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Save Changes'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showChangePasswordDialog(),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change Password'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
