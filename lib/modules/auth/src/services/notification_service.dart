import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/modules/auth/src/models/notification_model.dart';
import 'package:couple_guard/core/configs/api_config.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchNotifications({
    required String authToken,
    required String deviceId, // Ganti dari childId, ubah ke String
    String? startDate,
    String? endDate,
    String? appName, // Ganti dari appPackage
    int limit = 100,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (appName != null) 'app_name': appName,
    };

    final uri = Uri.parse(
      '$_baseUrl/api/notifications/$deviceId',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final notifications = (jsonResponse['data'] as List)
            .map((n) => NotificationModel.fromJson(n))
            .toList();

        return {'notifications': notifications, 'success': true};
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
