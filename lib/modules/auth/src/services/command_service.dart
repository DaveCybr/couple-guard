import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_guard/core/configs/api_config.dart';

class CommandService {
  final String _baseUrl = ApiConfig.baseUrl; // ganti sesuai URL backend

  // Build headers with auth token
  Future<Map<String, String>> _getHeaders(String token) async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Request failed');
    }
  }

  /// Send capture photo command
  ///
  /// [deviceId] - Target device ID
  /// [frontCamera] - Use front camera (default: true)
  Future<Map<String, dynamic>> capturePhoto({
    required String deviceId,
    required String authToken,
    bool frontCamera = true,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/capture-photo'),
        headers: headers,
        body: json.encode({'device_id': deviceId, 'front_camera': frontCamera}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  Future<Map<String, dynamic>> screenCapture({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/screen-capture'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Send request location command
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> requestLocation({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/request-location'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to request location: $e');
    }
  }

  /// Send start monitoring command
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> startMonitoring({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/start-monitoring'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to start monitoring: $e');
    }
  }

  /// Send stop monitoring command
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> stopMonitoring({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/stop-monitoring'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to stop monitoring: $e');
    }
  }

  /// Send start screen monitor command
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> startScreenMonitor({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/start-screen-monitor'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to start screen monitor: $e');
    }
  }

  /// Send stop screen monitor command
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> stopScreenMonitor({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/stop-screen-monitor'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to stop screen monitor: $e');
    }
  }

  /// Send custom command
  ///
  /// [deviceId] - Target device ID
  /// [command] - Command object with type and additional data
  Future<Map<String, dynamic>> sendCustomCommand({
    required String deviceId,
    required String authToken,
    required Map<String, dynamic> command,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/custom'),
        headers: headers,
        body: json.encode({'device_id': deviceId, 'command': command}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to send custom command: $e');
    }
  }

  /// Broadcast command to all parent's devices
  ///
  /// [command] - Command object with type and additional data
  Future<Map<String, dynamic>> broadcastCommand({
    required Map<String, dynamic> command,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/broadcast'),
        headers: headers,
        body: json.encode({'command': command}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to broadcast command: $e');
    }
  }

  /// Test FCM token validity
  ///
  /// [deviceId] - Target device ID
  Future<Map<String, dynamic>> testFcmToken({
    required String deviceId,
    required String authToken,
  }) async {
    try {
      final headers = await _getHeaders(authToken);
      final response = await http.post(
        Uri.parse('$_baseUrl/commands/test-fcm-token'),
        headers: headers,
        body: json.encode({'device_id': deviceId}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to test FCM token: $e');
    }
  }
}

// Example usage in your app
// 
// final commandService = CommandService(baseUrl: 'https://your.com');
//
// // Capture photo with front camera
// try {
//   final result = await commandService.capturePhoto(
//     deviceId: 'device_123',
//     frontCamera: true,
//   );
//   print('Command sent: ${result['message']}');
// } catch (e) {
//   print('Error: $e');
// }
//
// // Request location
// try {
//   final result = await commandService.requestLocation(
//     deviceId: 'device_123',
//   );
//   print('Location requested: ${result['success']}');
// } catch (e) {
//   print('Error: $e');
// }
//
// // Send custom command
// try {
//   final result = await commandService.sendCustomCommand(
//     deviceId: 'device_123',
//     command: {
//       'type': 'vibrate',
//       'duration': 1000,
//     },
//   );
//   print('Custom command sent');
// } catch (e) {
//   print('Error: $e');
// }
//
// // Broadcast to all devices
// try {
//   final result = await commandService.broadcastCommand(
//     command: {
//       'type': 'sync',
//     },
//   );
//   print('Broadcast result: ${result['message']}');
// } catch (e) {
//   print('Error: $e');
// }