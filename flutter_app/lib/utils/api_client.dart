import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A specialized error handler for API requests
class ApiError {
  final String message;
  final int? statusCode;
  final String? details;
  final bool isAuthError;
  final String errorSource;

  ApiError({
    required this.message,
    this.statusCode,
    this.details,
    this.isAuthError = false,
    this.errorSource = 'server',
  });

  @override
  String toString() {
    return 'ApiError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? '\nDetails: $details' : ''}';
  }

  /// Returns true if this is an error that should trigger a retry
  bool get shouldRetry =>
      statusCode == 500 ||
      errorSource == 'connection' ||
      message.contains('timeout');

  /// Returns true if this is an authentication error
  bool get isAuthenticationError =>
      isAuthError ||
      statusCode == 401 ||
      message.toLowerCase().contains('auth') ||
      message.toLowerCase().contains('login') ||
      message.toLowerCase().contains('token');
}

/// Utility class for improved API interactions with robust error handling
class ApiClient {
  static const String baseUrl = 'http://10.0.2.2/fypProject/api/v1';
  static const int maxRetries = 2;
  static const int defaultTimeout = 15;

  /// Formats an API endpoint URL
  static Uri formatUrl(String endpoint, {Map<String, dynamic>? queryParams}) {
    return Uri.parse('$baseUrl/$endpoint')
        .replace(queryParameters: queryParams);
  }

  /// Gets a token from SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error retrieving token: $e');
      return null;
    }
  }

  /// Sets a token in SharedPreferences
  static Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// Clears the auth token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  /// Gets HTTP headers with optional auth token
  static Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
    bool isMultipart = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (includeAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Performs a GET request with robust error handling
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    int timeoutSeconds = defaultTimeout,
    int retryCount = 0,
  }) async {
    try {
      final url = formatUrl(endpoint, queryParams: queryParams);
      debugPrint('🔷 GET REQUEST: $url');

      final headers = await getHeaders(includeAuth: includeAuth);
      debugPrint('🔷 HEADERS: $headers');

      final response = await http
          .get(
        url,
        headers: headers,
      )
          .timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw ApiError(
            message: 'Request timed out',
            errorSource: 'connection',
          );
        },
      );

      return processResponse(
        response,
        endpoint,
        retryCount: retryCount,
        includeAuth: includeAuth,
      );
    } on SocketException catch (e) {
      debugPrint('🔴 SOCKET ERROR: $e');
      throw ApiError(
        message: 'Network connection error',
        details: e.message,
        errorSource: 'connection',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 TIMEOUT ERROR: $e');
      throw ApiError(
        message: 'Request timed out',
        details: e.message,
        errorSource: 'connection',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('🔴 UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  /// Performs a POST request with robust error handling
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    bool includeAuth = true,
    int timeoutSeconds = defaultTimeout,
    int retryCount = 0,
  }) async {
    try {
      final url = formatUrl(endpoint);
      debugPrint('🔷 POST REQUEST: $url');

      final headers = await getHeaders(includeAuth: includeAuth);
      debugPrint('🔷 HEADERS: $headers');
      debugPrint('🔷 BODY: ${jsonEncode(data)}');

      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode(data),
      )
          .timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw ApiError(
            message: 'Request timed out',
            errorSource: 'connection',
          );
        },
      );

      return processResponse(
        response,
        endpoint,
        retryCount: retryCount,
        includeAuth: includeAuth,
        data: data,
      );
    } on SocketException catch (e) {
      debugPrint('🔴 SOCKET ERROR: $e');
      throw ApiError(
        message: 'Network connection error',
        details: e.message,
        errorSource: 'connection',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 TIMEOUT ERROR: $e');
      throw ApiError(
        message: 'Request timed out',
        details: e.message,
        errorSource: 'connection',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('🔴 UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  /// Uploads a file with other form data
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required File file,
    required String fileField,
    required Map<String, String> fields,
    bool includeAuth = true,
    int timeoutSeconds = 30,
    int retryCount = 0,
  }) async {
    try {
      final url = formatUrl(endpoint);
      debugPrint('🔷 UPLOAD REQUEST: $url');

      final headers =
          await getHeaders(includeAuth: includeAuth, isMultipart: true);
      debugPrint('🔷 HEADERS: $headers');
      debugPrint('🔷 FIELDS: $fields');
      debugPrint('🔷 FILE PATH: ${file.path}');

      // Check if file exists
      if (!await file.exists()) {
        throw ApiError(
          message: 'File not found',
          details: 'The file at ${file.path} does not exist',
          errorSource: 'client',
        );
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll(headers);

      // Add fields
      request.fields.addAll(fields);

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
        filename: file.path.split('/').last,
      ));

      // Send request
      final streamedResponse = await request.send().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw ApiError(
            message: 'File upload timed out',
            errorSource: 'connection',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      return processResponse(
        response,
        endpoint,
        retryCount: retryCount,
        includeAuth: includeAuth,
        isMultipart: true,
        multipartFields: fields,
        multipartFile: file,
        multipartFileField: fileField,
      );
    } on SocketException catch (e) {
      debugPrint('🔴 SOCKET ERROR: $e');
      throw ApiError(
        message: 'Network connection error',
        details: e.message,
        errorSource: 'connection',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 TIMEOUT ERROR: $e');
      throw ApiError(
        message: 'File upload timed out',
        details: e.message,
        errorSource: 'connection',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      debugPrint('🔴 UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred during file upload',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  /// Processes API responses with retry capability for common errors
  static Future<Map<String, dynamic>> processResponse(
    http.Response response,
    String endpoint, {
    int retryCount = 0,
    bool includeAuth = true,
    dynamic data,
    bool isMultipart = false,
    Map<String, String>? multipartFields,
    File? multipartFile,
    String? multipartFileField,
  }) async {
    debugPrint('🔷 RESPONSE STATUS: ${response.statusCode}');
    debugPrint('🔷 RESPONSE BODY: ${_truncateLog(response.body)}');

    // Handle successful responses
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true};
        }

        final responseData = json.decode(response.body);
        return responseData is Map<String, dynamic>
            ? responseData
            : {'success': true, 'data': responseData};
      } catch (e) {
        debugPrint('🔴 ERROR PARSING RESPONSE: $e');
        throw ApiError(
          message: 'Invalid response format',
          statusCode: response.statusCode,
          details: e.toString(),
          errorSource: 'parsing',
        );
      }
    }

    // Special handling for 500 errors with empty response body (likely PHP error)
    if (response.statusCode == 500 &&
        (response.body.isEmpty || response.body.trim().length < 5) &&
        retryCount < maxRetries) {
      debugPrint('🟠 EMPTY OR MINIMAL 500 ERROR - Retrying request...');
      await Future.delayed(Duration(milliseconds: 800 * (retryCount + 1)));

      if (isMultipart &&
          multipartFile != null &&
          multipartFileField != null &&
          multipartFields != null) {
        // Retry multipart request
        return uploadFile(
          endpoint,
          file: multipartFile,
          fileField: multipartFileField,
          fields: multipartFields,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      } else if (data != null) {
        // Retry POST request
        return post(
          endpoint,
          data: data,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      } else {
        // Retry GET request
        return get(
          endpoint,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }
    }

    // Handle authentication errors
    if (response.statusCode == 401) {
      // Clear token on auth errors
      await clearToken();

      throw ApiError(
        message: 'Authentication required',
        statusCode: response.statusCode,
        details: 'Please log in to continue',
        isAuthError: true,
        errorSource: 'server',
      );
    }

    // Handle other errors
    try {
      Map<String, dynamic> errorData = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            errorData = decoded;
          } else {
            errorData = {'error': decoded.toString()};
          }
        } catch (e) {
          errorData = {'error': response.body};
        }
      }

      final errorMessage = errorData['error'] ?? 'Request failed';
      final errorDetails = errorData['message'] ?? errorData['details'];

      throw ApiError(
        message: errorMessage,
        statusCode: response.statusCode,
        details: errorDetails,
        isAuthError: errorMessage.toString().toLowerCase().contains('auth') ||
            errorMessage.toString().toLowerCase().contains('login') ||
            errorMessage.toString().toLowerCase().contains('token'),
        errorSource: 'server',
      );
    } catch (e) {
      if (e is ApiError) {
        throw e;
      }

      throw ApiError(
        message: 'Request failed',
        statusCode: response.statusCode,
        details: 'An error occurred processing the response',
        errorSource: 'server',
      );
    }
  }

  /// Truncates log output for large responses
  static String _truncateLog(String text) {
    if (text.length > 500) {
      return '${text.substring(0, 500)}... (truncated)';
    }
    return text;
  }

  /// Shows a user-friendly error dialog
  static void showErrorDialog(BuildContext context, ApiError error) {
    String title;
    String message;

    switch (error.errorSource) {
      case 'connection':
        title = 'Connection Error';
        message = 'Please check your internet connection and try again.';
        break;
      case 'parsing':
        title = 'Data Error';
        message = 'There was a problem processing the server response.';
        break;
      case 'server':
        title = 'Server Error';
        message = error.message;
        if (error.details != null && error.details!.isNotEmpty) {
          message += '\n\n${error.details}';
        }
        break;
      default:
        title = 'Error';
        message = error.message;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar with an error message
  static void showErrorSnackbar(BuildContext context, ApiError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }
}
