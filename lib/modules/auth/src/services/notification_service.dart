import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/modules/auth/src/models/notification_model.dart';
import 'package:couple_guard/core/configs/api_config.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl; // ganti sesuai URL backend

  Future<Map<String, dynamic>> fetchNotifications({
    required String authToken,
    required int childId,
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    int? priority,
    String? appPackage,
    bool? onlyFlagged,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority.toString(),
      if (appPackage != null) 'app_package': appPackage,
      if (onlyFlagged != null) 'only_flagged': onlyFlagged.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$_baseUrl/notification/list/$childId',
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
        final notifications =
            (jsonResponse['data'] as List)
                .map((n) => NotificationModel.fromJson(n))
                .toList();

        return {
          'notifications': notifications,
          'pagination': jsonResponse['pagination'],
          'summary': jsonResponse['summary'],
        };
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
