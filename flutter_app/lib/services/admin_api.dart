import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApi {
  static const String baseUrl =
      'http://10.0.2.2/fypProject'; // Using Android emulator's special IP for localhost
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Check if the current user has admin privileges
  static Future<bool> isAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('Admin check failed: No token found');
        return false;
      }

      print('Checking admin status: ${baseUrl}/check_admin.php');
      final response = await http.get(
        Uri.parse('${baseUrl}/check_admin.php'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      print('Admin check response status: ${response.statusCode}');
      print('Admin check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isAdmin = data['user']['is_admin'] ?? false;
        print('User is admin: $isAdmin');
        return isAdmin;
      }

      print('Admin check failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get all users (admin only)
  static Future<List<dynamic>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user_management_api.php?action=get_users'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['users'];
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch users');
        }
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get all items (admin can see all items)
  static Future<List<dynamic>> getAllItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Using the correct endpoint from ApiConfig
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/items_api.php?action=get_items&admin=true'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['items'];
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch items');
        }
      } else {
        print('Items API response: ${response.statusCode} ${response.body}');
        throw Exception('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  // Update user role (admin only)
  static Future<bool> updateUserRole(int userId, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user_management_api.php?action=set_role'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
        body: json.encode({'id': userId, 'role': role}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to update user role: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Get all donation centers
  static Future<List<dynamic>> getDonationCenters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/donation_api.php?action=centers'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      print(
          'Donation centers response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['centers'] ?? [];
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch donation centers');
        }
      } else {
        throw Exception(
          'Failed to fetch donation centers: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching donation centers: $e');
      return [];
    }
  }

  // Add new donation center (admin only)
  static Future<bool> addDonationCenter(Map<String, dynamic> centerData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/donation_centers_api.php?action=add_center'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
        body: json.encode(centerData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception(
          'Failed to add donation center: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error adding donation center: $e');
      return false;
    }
  }

  // Get admin dashboard statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user_management_api.php?action=get_stats'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['stats'];
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch statistics');
        }
      } else {
        throw Exception('Failed to fetch statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      return {};
    }
  }

  // Update donation center (admin only)
  static Future<bool> updateDonationCenter(
      Map<String, dynamic> centerData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/donation_centers_api.php?action=update_center'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
        body: json.encode(centerData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception(
          'Failed to update donation center: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating donation center: $e');
      return false;
    }
  }

  // Get donations for a center (admin only)
  static Future<List<dynamic>> getDonations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/donation_centers_api.php?action=get_donations'),
        headers: {...jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['donations'] ?? [];
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch donations');
        }
      } else {
        throw Exception(
          'Failed to fetch donations: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching donations: $e');
      return [];
    }
  }
}
