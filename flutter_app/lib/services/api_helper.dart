import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // Base URL for API endpoints
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  static const String _baseUrl = 'http://10.0.2.2/fypProject/api/v1';

  // Token management methods
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers for API requests
  Future<Map<String, String>> _getHeaders(
      {bool requiresAuth = true, bool isMultipart = false}) async {
    Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await getToken();
      print('Retrieved token from storage: $token'); // Debug log

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print(
            'Added Authorization header: ${headers['Authorization']}'); // Debug log
      } else {
        print('No auth token found in storage!'); // Debug log
      }
    } else {
      print('Auth not required for this request'); // Debug log
    }

    print('Final headers: $headers'); // Debug log
    return headers;
  }

  // Handle API responses and errors
  dynamic _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}'); // Debug log
    print('Response body: ${response.body}'); // Debug log

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        // Handle empty response body
        if (response.body.isEmpty) {
          print(
              'Warning: Empty response body with status ${response.statusCode}');
          return {
            'success': true,
            'message': 'Operation completed successfully'
          };
        }
        // Decode and explicitly cast to Map<String, dynamic>
        final dynamic decodedJson = json.decode(response.body);
        return Map<String, dynamic>.from(decodedJson);
      } catch (e) {
        print('Error decoding successful response: $e'); // Debug log
        return {
          'success': false,
          'error': 'Failed to decode server response: $e'
        };
      }
    } else if (response.statusCode == 401) {
      print('Unauthorized access - token may be invalid'); // Debug log
      throw Exception('Unauthorized access. Please log in again.');
    } else if (response.statusCode == 403) {
      print('Forbidden access - insufficient permissions'); // Debug log
      throw Exception('You do not have permission to perform this action.');
    } else if (response.statusCode == 404) {
      print('Resource not found'); // Debug log
      throw Exception('The requested resource was not found.');
    } else if (response.statusCode == 400) {
      try {
        if (response.body.isEmpty) {
          throw Exception('Invalid request with no details');
        }
        final errorData = json.decode(response.body);
        print('Bad request: $errorData'); // Debug log
        throw Exception(errorData['error'] ?? 'Invalid request');
      } catch (e) {
        print('Error decoding 400 response: $e'); // Debug log
        throw Exception('Invalid request');
      }
    } else if (response.statusCode == 500) {
      try {
        if (response.body.isEmpty) {
          print('Server returned 500 with empty body');
          throw Exception(
              'Server error: The server encountered an internal error');
        }
        final errorData = json.decode(response.body);
        print('Server error: $errorData'); // Debug log
        throw Exception(
            'Server error: ${errorData['error'] ?? 'Unknown error'}');
      } catch (e) {
        print('Error decoding 500 response: $e'); // Debug log
        throw Exception('An internal server error occurred');
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        print('Other error: $errorData'); // Debug log
        throw Exception(errorData['error'] ?? 'Request failed');
      } catch (e) {
        print('Error decoding error response: $e'); // Debug log
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  // Item endpoints
  Future<Map<String, dynamic>> getItems(
      {int page = 1, String? category}) async {
    try {
      final params = {
        'action': 'get_items',
        'page': page.toString(),
        if (category != null) 'category': category,
      };

      final url =
          Uri.parse('$_baseUrl/items_api.php').replace(queryParameters: params);

      print('Request URL: $url'); // Debug print

      final response = await http
          .get(
        url,
        headers: await _getHeaders(requiresAuth: false),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      // Check if the server is properly accessible
      if (response.statusCode == 500 && response.body.isEmpty) {
        print('Server error with empty response - might be PHP error');

        // Wait briefly then retry once
        await Future.delayed(const Duration(seconds: 1));
        final retryResponse = await http
            .get(
          url,
          headers: await _getHeaders(requiresAuth: false),
        )
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Connection timed out on retry.');
          },
        );

        // If retry worked, return that response
        if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
          return _handleResponse(retryResponse);
        } else {
          // Return a friendly error message
          return {
            'success': false,
            'error': 'Server error',
            'message':
                'The server is currently unavailable. Please check your connection and try again later.',
            'items': [],
            'pagination': {'total': 0, 'page': 1, 'limit': 10, 'pages': 0}
          };
        }
      }

      return _handleResponse(response);
    } catch (e) {
      print('Error in getItems: $e');

      // Return a structured error response instead of throwing
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
        'items': [],
        'pagination': {'total': 0, 'page': 1, 'limit': 10, 'pages': 0}
      };
    }
  }

  Future<Map<String, dynamic>> getItemDetails(int itemId) async {
    try {
      final url =
          Uri.parse('$_baseUrl/items_api.php?action=get_item&id=$itemId');
      final response = await http
          .get(
        url,
        headers: await _getHeaders(requiresAuth: false),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in getItemDetails: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
        'item': null
      };
    }
  }

  Future<Map<String, dynamic>> searchItems(String query) async {
    try {
      final url = Uri.parse('$_baseUrl/items_api.php?action=search&q=$query');
      final response = await http
          .get(
        url,
        headers: await _getHeaders(requiresAuth: false),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in searchItems: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
        'items': []
      };
    }
  }
}
