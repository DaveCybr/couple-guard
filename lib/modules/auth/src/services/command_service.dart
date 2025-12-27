import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_guard/core/configs/api_config.dart';

class CommandService {
  final String _baseUrl = ApiConfig.baseUrl;

  // Build headers with auth token
  Future<Map<String, String>> _getHeaders(String token) async {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Handle API response with better error handling
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Log response for debugging
    print('Response Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');

    // Check if response is HTML (redirect or error page)
    if (response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      throw Exception(
        'Server returned HTML instead of JSON. '
        'Status: ${response.statusCode}. '
        'This might indicate wrong URL or server redirect. '
        'Check your base URL: $_baseUrl',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Failed to parse JSON response: $e');
      }
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(
          error['message'] ??
              'Request failed with status ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    }
  }

  /// Send capture photo command
  Future<Map<String, dynamic>> capturePhoto({
    required String deviceId,
    required String authToken,
    bool frontCamera = true,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/capture-photo';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId, 'front_camera': frontCamera}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Send screen capture command
  Future<Map<String, dynamic>> screenCapture({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/screen-capture';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to capture screen: $e');
    }
  }

  /// Send request location command
  Future<Map<String, dynamic>> requestLocation({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/request-location';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to request location: $e');
    }
  }

  /// Send start monitoring command
  Future<Map<String, dynamic>> startMonitoring({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/start-monitoring';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to start monitoring: $e');
    }
  }

  /// Send stop monitoring command
  Future<Map<String, dynamic>> stopMonitoring({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/stop-monitoring';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to stop monitoring: $e');
    }
  }

  /// Send start screen monitor command
  Future<Map<String, dynamic>> startScreenMonitor({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/start-screen-monitor';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to start screen monitor: $e');
    }
  }

  /// Send stop screen monitor command
  Future<Map<String, dynamic>> stopScreenMonitor({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/stop-screen-monitor';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to stop screen monitor: $e');
    }
  }

  /// Send custom command
  Future<Map<String, dynamic>> sendCustomCommand({
    required String deviceId,
    required String authToken,
    required Map<String, dynamic> command,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/custom';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId, 'command': command}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to send custom command: $e');
    }
  }

  /// Broadcast command to all parent's devices
  Future<Map<String, dynamic>> broadcastCommand({
    required Map<String, dynamic> command,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/broadcast';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'command': command}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to broadcast command: $e');
    }
  }

  /// Test FCM token validity
  Future<Map<String, dynamic>> testFcmToken({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final url = '$_baseUrl/commands/test-fcm-token';
      print('Calling API: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to test FCM token: $e');
    }
  }
}
