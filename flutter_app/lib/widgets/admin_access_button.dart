import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_api.dart';

class AdminAccessButton extends StatefulWidget {
  const AdminAccessButton({Key? key}) : super(key: key);

  @override
  State<AdminAccessButton> createState() => _AdminAccessButtonState();
}

class _AdminAccessButtonState extends State<AdminAccessButton> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminApi.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton.icon(
        onPressed: () => context.go('/admin'),
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Admin Dashboard'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
