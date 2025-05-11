import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Helper class to improve error handling and reporting in the app
class ApiError {
  final String message;
  final int? statusCode;
  final String? details;
  final String errorSource;

  ApiError({
    required this.message,
    this.statusCode,
    this.details,
    this.errorSource = 'server',
  });

  @override
  String toString() {
    return 'ApiError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? '\nDetails: $details' : ''}';
  }
}

/// Helper class for robust API call handling
class ApiHelper {
  static const String baseUrl = 'http://10.0.2.2/fypProject/api/v1';
  static const String baseServerUrl = 'http://10.0.2.2/fypProject';

  /// Formats an image URL by ensuring it has the proper server prefix
  static String formatImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return ''; // Return empty string for null or empty URLs
    }

    // If the URL already starts with http, it's already absolute
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it starts with a slash, it's a server-relative path
    if (imageUrl.startsWith('/')) {
      return '$baseServerUrl$imageUrl';
    }

    // Otherwise, assume it needs both a slash and the base URL
    return '$baseServerUrl/$imageUrl';
  }

  /// Helper method to perform robust GET requests
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      final Uri url =
          Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);

      print('REQUEST GET: $url');

      final response = await http
          .get(
        url,
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw ApiError(
            message: 'Request timed out',
            errorSource: 'connection',
          );
        },
      );

      print('RESPONSE STATUS: ${response.statusCode}');
      print('RESPONSE HEADERS: ${response.headers}');

      // Successful response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          print('RESPONSE BODY: empty');
          return {'success': true};
        }

        try {
          print('RESPONSE BODY: ${_truncateLog(response.body)}');
          final data = json.decode(response.body);
          return data;
        } catch (e) {
          print('JSON DECODE ERROR: $e');
          throw ApiError(
            message: 'Failed to parse server response',
            statusCode: response.statusCode,
            details: e.toString(),
            errorSource: 'parsing',
          );
        }
      }

      // Error response
      print('ERROR RESPONSE: ${_truncateLog(response.body)}');

      // Special handling for 500 errors with empty body (likely PHP error)
      if (response.statusCode == 500 && response.body.isEmpty) {
        print('EMPTY 500 ERROR DETECTED - Likely PHP error');

        // Retry once after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        print('RETRYING REQUEST AFTER 500 ERROR');

        try {
          final retryResponse = await http
              .get(
            url,
            headers: headers,
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ApiError(
                message: 'Retry request timed out',
                errorSource: 'connection',
              );
            },
          );

          // If retry succeeded
          if (retryResponse.statusCode >= 200 &&
              retryResponse.statusCode < 300) {
            if (retryResponse.body.isEmpty) {
              return {'success': true};
            }

            final data = json.decode(retryResponse.body);
            return data;
          }
        } catch (retryError) {
          print('RETRY FAILED: $retryError');
          // Fall through to original error handling
        }

        // If we reached here, the retry also failed
        throw ApiError(
          message: 'Server is experiencing technical difficulties',
          statusCode: 500,
          details:
              'The server encountered an error. This might be a temporary issue, please try again later.',
          errorSource: 'server',
        );
      }

      // Try to parse error details
      Map<String, dynamic> errorData = {};
      try {
        if (response.body.isNotEmpty) {
          errorData = json.decode(response.body);
        }
      } catch (_) {
        // If error response is not JSON, use the raw response
        errorData = {'error': response.body};
      }

      throw ApiError(
        message: errorData['error'] ?? 'Request failed',
        statusCode: response.statusCode,
        details: errorData['message'] ?? errorData['details'],
        errorSource: 'server',
      );
    } on SocketException catch (e) {
      print('SOCKET EXCEPTION: $e');
      throw ApiError(
        message: 'Network connection error',
        details: 'Please check your internet connection and try again.',
        errorSource: 'connection',
      );
    } on FormatException catch (e) {
      print('FORMAT EXCEPTION: $e');
      throw ApiError(
        message: 'Invalid response format',
        details: e.toString(),
        errorSource: 'parsing',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  /// Helper method to perform robust POST requests
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = false,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/$endpoint');

      print('REQUEST POST: $url');
      print('REQUEST BODY: ${_truncateLog(body.toString())}');

      final response = await http
          .post(
        url,
        headers: headers,
        body: body is String ? body : json.encode(body),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw ApiError(
            message: 'Request timed out',
            errorSource: 'connection',
          );
        },
      );

      print('RESPONSE STATUS: ${response.statusCode}');
      print('RESPONSE HEADERS: ${response.headers}');

      // Successful response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          print('RESPONSE BODY: empty');
          return {'success': true};
        }

        try {
          print('RESPONSE BODY: ${_truncateLog(response.body)}');
          final data = json.decode(response.body);
          return data;
        } catch (e) {
          print('JSON DECODE ERROR: $e');
          throw ApiError(
            message: 'Failed to parse server response',
            statusCode: response.statusCode,
            details: e.toString(),
            errorSource: 'parsing',
          );
        }
      }

      // Error response
      print('ERROR RESPONSE: ${_truncateLog(response.body)}');

      // Special handling for 500 errors with empty body (likely PHP error)
      if (response.statusCode == 500 && response.body.isEmpty) {
        print('EMPTY 500 ERROR DETECTED - Likely PHP error');

        // Retry once after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        print('RETRYING POST REQUEST AFTER 500 ERROR');

        try {
          final retryResponse = await http
              .post(
            url,
            headers: headers,
            body: body is String ? body : json.encode(body),
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ApiError(
                message: 'Retry request timed out',
                errorSource: 'connection',
              );
            },
          );

          // If retry succeeded
          if (retryResponse.statusCode >= 200 &&
              retryResponse.statusCode < 300) {
            if (retryResponse.body.isEmpty) {
              return {'success': true};
            }

            final data = json.decode(retryResponse.body);
            return data;
          }
        } catch (retryError) {
          print('RETRY FAILED: $retryError');
          // Fall through to original error handling
        }

        // If we reached here, the retry also failed
        throw ApiError(
          message: 'Server is experiencing technical difficulties',
          statusCode: 500,
          details:
              'The server encountered an error. This might be a temporary issue, please try again later.',
          errorSource: 'server',
        );
      }

      // Try to parse error details
      Map<String, dynamic> errorData = {};
      try {
        if (response.body.isNotEmpty) {
          errorData = json.decode(response.body);
        }
      } catch (_) {
        // If error response is not JSON, use the raw response
        errorData = {'error': response.body};
      }

      throw ApiError(
        message: errorData['error'] ?? 'Request failed',
        statusCode: response.statusCode,
        details: errorData['message'] ?? errorData['details'],
        errorSource: 'server',
      );
    } on SocketException catch (e) {
      print('SOCKET EXCEPTION: $e');
      throw ApiError(
        message: 'Network connection error',
        details: 'Please check your internet connection and try again.',
        errorSource: 'connection',
      );
    } on FormatException catch (e) {
      print('FORMAT EXCEPTION: $e');
      throw ApiError(
        message: 'Invalid response format',
        details: e.toString(),
        errorSource: 'parsing',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  /// Helper method to upload files with proper error handling
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/$endpoint');

      print('FILE UPLOAD REQUEST: $url');
      print('FILE PATH: ${file.path}');

      final request = http.MultipartRequest('POST', url);

      // Add headers
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Add fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value;
          print('FIELD: $key = $value');
        });
      }

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        fileField,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );

      request.files.add(multipartFile);

      print('Sending multipart request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiError(
            message: 'File upload timed out',
            errorSource: 'connection',
          );
        },
      );

      print('RESPONSE STATUS: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);

      print('RESPONSE HEADERS: ${response.headers}');

      // Successful response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          print('RESPONSE BODY: empty');
          return {'success': true};
        }

        try {
          print('RESPONSE BODY: ${_truncateLog(response.body)}');
          final data = json.decode(response.body);
          return data;
        } catch (e) {
          print('JSON DECODE ERROR: $e');
          throw ApiError(
            message: 'Failed to parse server response',
            statusCode: response.statusCode,
            details: e.toString(),
            errorSource: 'parsing',
          );
        }
      }

      // Error response
      print('ERROR RESPONSE: ${_truncateLog(response.body)}');

      // Special handling for 500 errors with empty body (likely PHP error)
      if (response.statusCode == 500 && response.body.isEmpty) {
        print('EMPTY 500 ERROR DETECTED - Likely PHP error with file upload');

        // For file uploads, we need to create a completely new request for retry
        await Future.delayed(const Duration(seconds: 1));
        print('RETRYING FILE UPLOAD AFTER 500 ERROR');

        try {
          // Create a new request
          final retryRequest = http.MultipartRequest('POST', url);

          // Add headers
          if (headers != null) {
            retryRequest.headers.addAll(headers);
          }

          // Add fields
          if (fields != null) {
            retryRequest.fields.addAll(fields);
          }

          // Add file
          retryRequest.files.add(http.MultipartFile(
            fileField,
            file.openRead(),
            await file.length(),
            filename: file.path.split('/').last,
          ));

          final retryStreamedResponse = await retryRequest.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw ApiError(
                message: 'Retry file upload timed out',
                errorSource: 'connection',
              );
            },
          );

          final retryResponse =
              await http.Response.fromStream(retryStreamedResponse);

          // If retry succeeded
          if (retryResponse.statusCode >= 200 &&
              retryResponse.statusCode < 300) {
            if (retryResponse.body.isEmpty) {
              return {'success': true};
            }

            final data = json.decode(retryResponse.body);
            return data;
          }
        } catch (retryError) {
          print('RETRY FAILED: $retryError');
          // Fall through to original error handling
        }

        // If we reached here, the retry also failed
        throw ApiError(
          message: 'File upload failed',
          statusCode: 500,
          details:
              'The server encountered an error while processing your file. Please try again later.',
          errorSource: 'server',
        );
      }

      // Try to parse error details for non-empty responses
      Map<String, dynamic> errorData = {};
      try {
        if (response.body.isNotEmpty) {
          errorData = json.decode(response.body);
        }
      } catch (_) {
        // If error response is not JSON, use the raw response
        errorData = {'error': response.body};
      }

      throw ApiError(
        message: errorData['error'] ?? 'Upload failed',
        statusCode: response.statusCode,
        details: errorData['message'] ?? errorData['details'],
        errorSource: 'server',
      );
    } on SocketException catch (e) {
      print('SOCKET EXCEPTION: $e');
      throw ApiError(
        message: 'Network connection error',
        details: 'Please check your internet connection and try again.',
        errorSource: 'connection',
      );
    } on FormatException catch (e) {
      print('FORMAT EXCEPTION: $e');
      throw ApiError(
        message: 'Invalid response format',
        details: e.toString(),
        errorSource: 'parsing',
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      throw ApiError(
        message: 'An unexpected error occurred',
        details: e.toString(),
        errorSource: 'unknown',
      );
    }
  }

  // Utility to prevent very large responses from flooding logs
  static String _truncateLog(String text) {
    if (text.length > 500) {
      return '${text.substring(0, 500)}... (truncated)';
    }
    return text;
  }

  // Display user-friendly error dialog
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
}
