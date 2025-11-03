import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/modules/auth/src/models/notification_model.dart';
import 'package:couple_guard/core/configs/api_config.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchNotifications({
    required String authToken,
    required String deviceId,
    String? startDate,
    String? endDate,
    String? appName,
    int limit = 100,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (appName != null) 'app_name': appName,
    };

    final uri = Uri.parse(
      '$_baseUrl/notifications/$deviceId',
    ).replace(queryParameters: queryParams);

    print("🔗 API URL: $uri");
    print("📱 Device ID: $deviceId");
    print("📱 Device ID type: ${deviceId.runtimeType}");
    print("🔑 Token length: ${authToken.length}");

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );

    print("📡 Response Status: ${response.statusCode}");
    print("📡 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print("✅ JSON Response: $jsonResponse");

      if (jsonResponse['success'] == true) {
        // DEBUG: Check data structure before mapping
        print(
          "📋 Notifications data type: ${jsonResponse['data'].runtimeType}",
        );
        if (jsonResponse['data'] is List) {
          print(
            "📋 Number of notifications: ${(jsonResponse['data'] as List).length}",
          );
          if ((jsonResponse['data'] as List).isNotEmpty) {
            print(
              "📋 First notification: ${(jsonResponse['data'] as List).first}",
            );
            print(
              "📋 First notification type: ${(jsonResponse['data'] as List).first.runtimeType}",
            );
          }
        }

        try {
          final notifications = (jsonResponse['data'] as List).map((n) {
            print("🔄 Mapping notification: $n");
            return NotificationModel.fromJson(n);
          }).toList();

          return {'notifications': notifications, 'success': true};
        } catch (e) {
          print("❌ Error during mapping: $e");
          print("❌ Stack trace: ${e.toString()}");
          rethrow;
        }
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to fetch notifications',
        );
      }
    } else {
      throw Exception(
        'Failed to load notifications (Status ${response.statusCode})',
      );
    }
  }
}
