import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:couple_guard/core/configs/api_config.dart';

// Model untuk Screenshot
class ScreenshotModel {
  final int id;
  final String deviceId;
  final String fileUrl;
  final DateTime timestamp;

  ScreenshotModel({
    required this.id,
    required this.deviceId,
    required this.fileUrl,
    required this.timestamp,
  });

  factory ScreenshotModel.fromJson(Map<String, dynamic> json) {
    return ScreenshotModel(
      id: json['id'],
      deviceId: json['device_id']?.toString() ?? '',
      fileUrl: json['file_url'] ?? '', // Gunakan file_url dari response
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Full URL untuk gambar (sudah lengkap dari API)
  String get fullImageUrl => fileUrl;
}

// Service untuk Screenshot API
class ScreenshotService {
  final String authToken;
  final String _baseUrl = ApiConfig.baseUrl;

  ScreenshotService({required this.authToken});

  // Get list screenshots dengan filter opsional
  Future<List<ScreenshotModel>?> getScreenshots({
    required String deviceId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl/screenshots/$deviceId');

      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      queryParams['limit'] = limit.toString();

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      debugPrint('📡 Meminta screenshots dari: $uri');

      final response = await http.get(uri, headers: headers);
      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('📦 Response Body: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as List;

          List<ScreenshotModel> screenshots = data
              .map(
                (e) => ScreenshotModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();

          debugPrint('🎯 Berhasil memuat ${screenshots.length} screenshot(s)');
          return screenshots;
        } else {
          debugPrint('⚠️ Response success=false atau data kosong.');
        }
      } else {
        debugPrint('❌ Gagal memuat screenshots.');
        debugPrint('   ↳ Status Code: ${response.statusCode}');
        debugPrint('   ↳ Body: ${response.body}');
      }

      return null;
    } catch (e, stack) {
      debugPrint('🚨 Exception dalam getScreenshots: $e');
      debugPrint('📄 Stack trace: $stack');
      return null;
    }
  }

  // Delete screenshot
  Future<bool> deleteScreenshot(int screenshotId) async {
    try {
      final url = Uri.parse('$_baseUrl/screenshots/$screenshotId');

      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      debugPrint('🗑️ Menghapus screenshot ID: $screenshotId');

      final response = await http.delete(url, headers: headers);
      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ Screenshot berhasil dihapus');
        return responseData['success'] == true;
      }

      debugPrint('❌ Gagal menghapus screenshot');
      return false;
    } catch (e) {
      debugPrint('❌ Exception in deleteScreenshot: $e');
      return false;
    }
  }
}
