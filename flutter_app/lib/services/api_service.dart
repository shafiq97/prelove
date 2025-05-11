import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Retrieved token from storage: $token'); // Debug log

      if (token != null && token.isNotEmpty) {
        // Make sure we're using the exact same case for the header name that the server expects
        headers['Authorization'] = 'Bearer $token';
        print(
            'Added Authorization header: ${headers['Authorization']}'); // Debug log
      } else {
        print('No auth token found in storage or token is empty!'); // Debug log
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

        // Directly return the decoded JSON if it's already a Map
        if (decodedJson is Map<String, dynamic>) {
          return decodedJson;
        }

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

      // Try to parse the error message from the response if available
      String errorMessage = 'Unauthorized access. Please log in again.';
      try {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        }
      } catch (_) {}

      return {'success': false, 'error': errorMessage, 'status': 401};
    } else if (response.statusCode == 403) {
      print('Forbidden access - insufficient permissions'); // Debug log

      String errorMessage =
          'You do not have permission to perform this action.';
      try {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        }
      } catch (_) {}

      return {'success': false, 'error': errorMessage, 'status': 403};
    } else if (response.statusCode == 404) {
      print('Resource not found'); // Debug log

      String errorMessage = 'The requested resource was not found.';
      try {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        }
      } catch (_) {}

      return {'success': false, 'error': errorMessage, 'status': 404};
    } else if (response.statusCode == 400) {
      try {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'error': 'Invalid request with no details',
            'status': 400
          };
        }
        final errorData = json.decode(response.body);
        print('Bad request: $errorData'); // Debug log

        return {
          'success': false,
          'error': errorData['error'] ?? 'Invalid request',
          'status': 400
        };
      } catch (e) {
        print('Error decoding 400 response: $e'); // Debug log
        return {'success': false, 'error': 'Invalid request', 'status': 400};
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

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=login');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: false),
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyToken() async {
    try {
      print('Verifying token...'); // Debug log
      final url = Uri.parse('$_baseUrl/auth_api.php?action=verify-token');

      final token = await getToken();
      print('Current token: $token'); // Debug log

      if (token == null) {
        print('No token found in storage'); // Debug log
        return {'success': false, 'error': 'No authentication token found'};
      }

      final headers = await _getHeaders(requiresAuth: true);
      print('Request headers: $headers'); // Debug log

      final response = await http.get(url, headers: headers);
      print(
          'Token verification response status: ${response.statusCode}'); // Debug log
      print('Token verification response body: ${response.body}'); // Debug log

      if (response.statusCode == 401) {
        print('Token invalid or expired'); // Debug log
        await clearToken(); // Clear invalid token
        return {'success': false, 'error': 'Authentication token expired'};
      }

      return _handleResponse(response);
    } catch (e) {
      print('Error verifying token: $e'); // Debug log
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required bool termsAccepted,
    String? phone,
    String? address,
    String? recaptchaResponse,
  }) async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=register');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: false),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'terms_accepted': termsAccepted,
        'recaptcha_response': recaptchaResponse,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['token'] != null) {
        await setToken(data['token']);
      }
    }

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=logout');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    );

    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    return _handleResponse(response);
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=get_profile');
    final response = await http.get(
      url,
      headers:
          await _getHeaders(requiresAuth: false), // Changed to not require auth
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? profileImage,
  }) async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=update_profile');

    // Create multipart request if profile image is included
    if (profileImage != null) {
      var request = http.MultipartRequest('POST', url);
      final headers = await _getHeaders();
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      request.fields['full_name'] = fullName ?? '';
      request.fields['email'] = email ?? '';
      request.fields['phone'] = phone ?? '';
      request.fields['address'] = address ?? '';

      request.files.add(
        await http.MultipartFile.fromPath('profile_image', profileImage),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } else {
      // Standard JSON request if no image is being uploaded
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'address': address,
        }),
      );

      return _handleResponse(response);
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
    final url = Uri.parse('$_baseUrl/items_api.php?action=get_item&id=$itemId');
    final response = await http.get(
      url,
      headers: await _getHeaders(requiresAuth: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchItems(String query) async {
    final url = Uri.parse('$_baseUrl/items_api.php?action=search&q=$query');
    final response = await http.get(
      url,
      headers: await _getHeaders(requiresAuth: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createItem({
    required String name,
    required String description,
    required double price,
    required String condition,
    required String category,
    required String size,
    required String brand,
    required String color,
    String? imagePath,
  }) async {
    print('Creating item...'); // Debug log
    final url = Uri.parse(ApiConfig.createItem);
    print('Request URL: $url'); // Debug log

    try {
      // First verify if we have a valid token
      final tokenValid = await verifyToken();
      if (!tokenValid['success']) {
        print('Token verification failed: ${tokenValid['error']}'); // Debug log
        throw Exception('Please log in again to continue');
      }

      try {
        if (imagePath != null) {
          var request = http.MultipartRequest('POST', url);

          // Get headers without Content-Type for multipart request
          final multipartHeaders =
              await _getHeaders(requiresAuth: true, isMultipart: true);
          print('Multipart request headers: $multipartHeaders'); // Debug log

          // Add headers to request
          multipartHeaders.forEach((key, value) {
            request.headers[key] = value;
          });

          // Add fields to request
          final fields = {
            'name': name,
            'description': description,
            'price': price.toString(),
            'condition': condition,
            'category': category,
            'size': size,
            'brand': brand,
            'color': color,
          };
          request.fields.addAll(fields);
          print('Request fields: ${request.fields}'); // Debug log

          // Validate image file exists
          if (!await File(imagePath).exists()) {
            print('Image file not found: $imagePath'); // Debug log
            throw Exception('Image file not found');
          }

          // Add image file
          request.files
              .add(await http.MultipartFile.fromPath('image', imagePath));
          print('Added image file: $imagePath'); // Debug log

          // Send request
          final streamedResponse = await request.send();
          print('Multipart request sent successfully'); // Debug log

          final response = await http.Response.fromStream(streamedResponse);
          print('Response status: ${response.statusCode}'); // Debug log
          print('Response headers: ${response.headers}'); // Debug log
          print('Response body: ${response.body}'); // Debug log

          return _handleResponse(response);
        } else {
          // Get headers for JSON request
          final jsonHeaders = await _getHeaders(requiresAuth: true);
          print('JSON request headers: $jsonHeaders'); // Debug log

          // Prepare the request body
          final body = json.encode({
            'name': name,
            'description': description,
            'price': price,
            'condition': condition,
            'category': category,
            'size': size,
            'brand': brand,
            'color': color,
          });
          print('Request body: $body'); // Debug log

          // Send the request
          final response = await http.post(
            url,
            headers: jsonHeaders,
            body: body,
          );
          print('Response status: ${response.statusCode}'); // Debug log
          print('Response headers: ${response.headers}'); // Debug log
          print('Response body: ${response.body}'); // Debug log

          return _handleResponse(response);
        }
      } catch (e) {
        print('Error sending multipart request: $e'); // Debug log
        throw Exception('Failed to upload image: ${e.toString()}');
      }
    } catch (e) {
      print('Error in createItem: $e'); // Debug log

      if (e.toString().contains('token') || e.toString().contains('auth')) {
        // Clear token on authentication errors
        await clearToken();
        throw Exception('Please log in again to continue');
      }

      throw Exception('Failed to create item: ${e.toString()}');
    }
  }

  // Cart endpoints
  Future<Map<String, dynamic>> getCartItems() async {
    final url = Uri.parse('$_baseUrl/cart_api.php?action=get_cart');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToCart(int itemId, int quantity) async {
    final url = Uri.parse(ApiConfig.addToCart);
    print('Adding to cart URL: $url'); // Debug print

    final headers = await _getHeaders();
    print('Request headers: $headers'); // Debug print

    final body = json.encode({
      'item_id': itemId,
      'quantity': quantity,
    });
    print('Request body: $body'); // Debug print

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    print('Response status: ${response.statusCode}'); // Debug print
    print('Response body: ${response.body}'); // Debug print

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCartQuantity(
      int cartId, int quantity) async {
    final url = Uri.parse('$_baseUrl/cart_api.php?action=update_quantity');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'cart_id': cartId,
        'quantity': quantity,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeFromCart(int cartId) async {
    final url = Uri.parse('$_baseUrl/cart_api.php?action=remove_from_cart');
    final response = await http.delete(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'cart_id': cartId,
      }),
    );

    return _handleResponse(response);
  }

  // Checkout endpoint
  Future<Map<String, dynamic>> checkout({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    final url = Uri.parse('$_baseUrl/cart_api.php?action=checkout');

    final headers = await _getHeaders();
    final body = {
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
    };

    print("Checkout URL: $url");
    print("Checkout Headers: $headers");
    print("Checkout Body: ${json.encode(body)}");

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    print("Checkout HTTP status: ${response.statusCode}");
    print("Checkout response body: ${response.body}");

    return _handleResponse(response);
  }

  // Order history endpoints
  Future<Map<String, dynamic>> getOrderHistory() async {
    final url = Uri.parse('$_baseUrl/cart_api.php?action=order_history');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url =
        Uri.parse('$_baseUrl/cart_api.php?action=order_details&id=$orderId');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Planner endpoints
  Future<Map<String, dynamic>> getPlannerOutfits() async {
    final url = Uri.parse('$_baseUrl/planner_api.php?action=get_outfits');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createOutfit({
    required String name,
    required List<int> itemIds,
    String? description,
  }) async {
    final url = Uri.parse('$_baseUrl/planner_api.php?action=create_outfit');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'description': description,
        'item_ids': itemIds,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteOutfit(int outfitId) async {
    final url = Uri.parse(
        '$_baseUrl/planner_api.php?action=delete_outfit&id=$outfitId');
    final response = await http.delete(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getEvents(
      {DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{
      'action': 'get_events', // Adding the missing action parameter
    };
    if (startDate != null) {
      params['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate.toIso8601String();
    }

    final url =
        Uri.parse('$_baseUrl/planner_api.php').replace(queryParameters: params);

    print('Events URL: $url'); // Debug log

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required DateTime date,
    String? notes,
    String? location,
    int? outfitId,
  }) async {
    final url = Uri.parse('$_baseUrl/planner_api.php?action=create_event');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'title': title,
        'event_date': date
            .toIso8601String(), // Changed 'date' to 'event_date' to match backend
        'description':
            notes, // Changed 'notes' to 'description' to match backend
        'location': location,
        'outfit_id': outfitId,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateEvent({
    required int eventId,
    String? title,
    DateTime? date,
    String? notes,
    int? outfitId,
  }) async {
    final url =
        Uri.parse('$_baseUrl/planner_api.php?action=update_event&id=$eventId');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'title': title,
        'date': date?.toIso8601String(),
        'notes': notes,
        'outfit_id': outfitId,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteEvent(int eventId) async {
    final url =
        Uri.parse('$_baseUrl/planner_api.php?action=delete_event&id=$eventId');
    final response = await http.delete(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Donation endpoints
  Future<Map<String, dynamic>> getDonationCenters() async {
    final url = Uri.parse('$_baseUrl/donation_api.php?action=centers');
    final response = await http.get(
      url,
      headers:
          await _getHeaders(requiresAuth: false), // Changed to not require auth
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserDonations() async {
    final url = Uri.parse('$_baseUrl/donation_api.php?action=user_donations');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> scheduleDonation({
    required int centerId,
    required DateTime scheduledDate,
  }) async {
    final url = Uri.parse('$_baseUrl/donation_api.php?action=schedule');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: true), // Require authentication
      body: json.encode({
        'center_id': centerId,
        'scheduled_date': scheduledDate.toIso8601String(),
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeDonation(int donationId) async {
    final url = Uri.parse('$_baseUrl/donation_api.php?action=complete');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'donation_id': donationId,
      }),
    );

    return _handleResponse(response);
  }

  // Settings endpoints
  Future<Map<String, dynamic>> getUserSettings() async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=get_settings');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Test token validation
  Future<Map<String, dynamic>> testToken() async {
    try {
      final url = Uri.parse('$_baseUrl/auth_api.php?action=test_token');

      print('Test token request URL: $url'); // Debug log

      final response = await http.get(
        url,
        headers:
            await _getHeaders(), // Use the same header creation method for consistency
      );

      print('Test token response status: ${response.statusCode}'); // Debug log
      print('Test token response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Test token error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to test token: ${e.toString()}',
      };
    }
  }

  // New test method for authentication issues
  Future<Map<String, dynamic>> testAuthentication() async {
    try {
      final url = Uri.parse('$_baseUrl/auth_test.php');

      print('Auth test request URL: $url'); // Debug log

      final response = await http.get(
        url,
        headers: await _getHeaders(), // Use the same header creation method
      );

      print('Auth test response status: ${response.statusCode}'); // Debug log
      print('Auth test response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Auth test error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to test authentication: ${e.toString()}',
      };
    }
  }

  // Debug token verification
  Future<Map<String, dynamic>> debugToken() async {
    try {
      final url = Uri.parse('$_baseUrl/debug_token.php');
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'No token available',
        };
      }

      // Explicitly set headers with token
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('Debug token request URL: $url'); // Debug log
      print('Debug token request headers: $headers'); // Debug log

      final response = await http.get(
        url,
        headers: headers,
      );

      print('Debug token response status: ${response.statusCode}'); // Debug log
      print('Debug token response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Debug token error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to debug token: ${e.toString()}',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final url = Uri.parse('$_baseUrl/auth_api.php?action=change_password');
      final token = await getToken();

      // Explicitly set headers with token
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('Change password request URL: $url'); // Debug log
      print('Change password request headers: $headers'); // Debug log
      print('Authorization header: ${headers['Authorization']}'); // Debug log

      final jsonBody = json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      print('Change password request body: $jsonBody'); // Debug log

      final response = await http.post(
        url,
        headers: headers,
        body: jsonBody,
      );

      print(
          'Change password response status: ${response.statusCode}'); // Debug log
      print('Change password response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Change password error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to change password: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserSettings({
    required bool darkMode,
    required bool notifications,
    required String language,
    required bool privacy,
    required bool showSoldItems,
    required bool showDonatedItems,
    required bool outfitSuggestions,
    required bool saleNotifications,
    required bool donationReminders,
  }) async {
    final url = Uri.parse('$_baseUrl/auth_api.php?action=update_settings');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'dark_mode': darkMode,
        'notifications': notifications,
        'language': language,
        'privacy': privacy,
        'show_sold_items': showSoldItems,
        'show_donated_items': showDonatedItems,
        'outfit_suggestions': outfitSuggestions,
        'sale_notifications': saleNotifications,
        'donation_reminders': donationReminders,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOutfit(String outfitId) async {
    try {
      // Try the action-based API endpoint first
      final url = Uri.parse(
          '$_baseUrl/planner_api.php?action=get_outfit&outfit_id=$outfitId');

      print('Requesting outfit details from: $url');

      final Map<String, String> headers = await _getHeaders();
      print('Using headers: $headers');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30)); // Longer timeout for debugging

      print('getOutfit response status: ${response.statusCode}');
      print('getOutfit response body length: ${response.body.length}');
      if (response.body.isNotEmpty) {
        print(
            'getOutfit response preview: ${response.body.substring(0, min(100, response.body.length))}');
      } else {
        print('getOutfit response body is empty');
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        try {
          final dynamic decodedJson = json.decode(response.body);

          // Explicitly cast to Map<String, dynamic>
          final Map<String, dynamic> jsonResponse =
              Map<String, dynamic>.from(decodedJson);

          // Validate response structure
          if (jsonResponse.containsKey('outfit')) {
            return jsonResponse;
          } else {
            print('Invalid response structure: $jsonResponse');
            return {
              'success': false,
              'error': 'Invalid response structure from server'
            };
          }
        } catch (e) {
          print('JSON decode error: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else if (response.statusCode == 500) {
        // Try fallback to path-based API endpoint if action-based fails
        print('Action-based API failed with 500, trying fallback');
        return _getOutfitFallback(outfitId);
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in getOutfit: $e');
      return {
        'success': false,
        'error': 'Failed to load outfit: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _getOutfitFallback(String outfitId) async {
    try {
      // Try path-based API as fallback
      final url = Uri.parse('$_baseUrl/planner_api.php/outfits/$outfitId');

      print('Using fallback URL: $url');

      final response = await http.get(url, headers: await _getHeaders());

      print('Fallback response status: ${response.statusCode}');
      print('Fallback response body: ${response.body}');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        try {
          final dynamic decodedJson = json.decode(response.body);
          // Explicitly cast to Map<String, dynamic>
          return Map<String, dynamic>.from(decodedJson);
        } catch (e) {
          print('JSON decode error in fallback: $e');
          return {
            'success': false,
            'error': 'Failed to parse server response: $e'
          };
        }
      } else {
        throw Exception('Server returned ${response.statusCode} in fallback');
      }
    } catch (e) {
      print('Error in fallback getOutfit: $e');
      return {
        'success': false,
        'error': 'Failed to load outfit: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateOutfit(
      String outfitId, Map<String, dynamic> outfitData) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/planner_api.php?action=update_outfit&id=$outfitId');
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          ...outfitData,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update outfit: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getOutfits() async {
    try {
      final url = Uri.parse('$_baseUrl/planner_api.php?action=get_outfits');
      final response = await http.get(url, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to load outfits: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/planner_api.php?action=get_events'),
        headers: await _getHeaders(),
      );
      print('Get user events response: ${response.body}'); // Debug log
      return _handleResponse(response);
    } catch (e) {
      print('Get user events error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to load user events: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> debugProfile() async {
    try {
      final url = Uri.parse('$_baseUrl/debug_profile.php');

      print('Debug profile request URL: $url'); // Debug log

      final response = await http.get(
        url,
        headers: await _getHeaders(), // Use the same header creation method
      );

      print(
          'Debug profile response status: ${response.statusCode}'); // Debug log
      print('Debug profile response body: ${response.body}'); // Debug log

      return _handleResponse(response);
    } catch (e) {
      print('Debug profile error: $e'); // Debug log
      return {
        'success': false,
        'error': 'Failed to debug profile: ${e.toString()}',
      };
    }
  }
}
