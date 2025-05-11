import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthService() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final savedToken = prefs.getString('auth_token');

      if (userData != null && savedToken != null) {
        _currentUser = User.fromJson(json.decode(userData));
        _token = savedToken;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load user data: $e');
      }
      // If loading fails, ensure we're in a clean logged out state
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('user_data', json.encode(_currentUser!.toJson()));
    }
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? address,
    bool termsAccepted = false,
    String? recaptchaResponse,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register.php');
      print('Making registration request to: $url'); // Debug print

      final requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone ?? '',
        'address': address ?? '',
      };
      print('Request body: ${json.encode(requestBody)}'); // Debug print

      final response = await http.post(url, body: requestBody);

      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        print('Registration successful'); // Debug print
      } else {
        print(
            'Registration failed with error: ${responseData['error']}'); // Debug print
        throw Exception(responseData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration exception: $e'); // Debug print
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConfig.login);
      print('Login URL: $url'); // Debug log

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': usernameOrEmail,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}'); // Debug log
      print('Login Response Body: ${response.body}'); // Debug log

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _token = responseData['token'];
        print('Received token: $_token'); // Debug log

        _currentUser = User.fromJson(responseData['user']);
        print(
            'Created user object: ${json.encode(_currentUser?.toJson())}'); // Debug log

        // Save both token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_currentUser!.toJson()));

        print(
            'Saved token to storage: ${prefs.getString('auth_token')}'); // Debug log
        print(
            'Saved user data to storage: ${prefs.getString('user_data')}'); // Debug log
      } else {
        print(
            'Login failed: ${responseData['error'] ?? 'Unknown error'}'); // Debug log
        throw Exception(responseData['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e'); // Debug log
      throw Exception('Authentication failed. Please check your credentials.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');

      _currentUser = null;
      _token = null;
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? email,
    String? phone,
    String? address,
    String? profileImageUrl,
  }) async {
    if (_token == null || _currentUser == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}/api/users/update_profile.php');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
        },
        body: {
          'full_name': fullName,
          'email': email ?? _currentUser!.email,
          'phone': phone ?? _currentUser!.phone ?? '',
          'address': address ?? _currentUser!.address ?? '',
          'profile_image_url':
              profileImageUrl ?? _currentUser!.profileImageUrl ?? '',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update current user with new data
        _currentUser = User(
          id: _currentUser!.id,
          username: _currentUser!.username,
          email: email ?? _currentUser!.email,
          fullName: fullName,
          phone: phone ?? _currentUser!.phone,
          address: address ?? _currentUser!.address,
          profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        );

        await _saveUserData();
      } else {
        throw Exception(responseData['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update profile error: $e');
      }
      throw Exception('Failed to update profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (_token == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}/api/auth/change_password.php');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
        },
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final responseData = json.decode(response.body);

      if (!(response.statusCode == 200 && responseData['success'] == true)) {
        throw Exception(responseData['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Change password error: $e');
      }
      throw Exception('Failed to change password: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update current user method
  void updateCurrentUser(User user) {
    _currentUser = user;
    _saveUserData();
    notifyListeners();
  }
}
