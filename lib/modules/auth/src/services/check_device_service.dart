import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/core/configs/api_config.dart';

class CheckPairedDeviceService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Cek apakah parent sudah memiliki device yang terhubung
  static Future<Map<String, dynamic>> checkConnectedDevices(
    int parentId,
    String token,
  ) async {
    try {
      print('🌐 API Call: POST $_baseUrl/auth/check-device');
      print('📦 Request Body: {"parent_id": $parentId}');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/check-device'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: json.encode({'parent_id': parentId}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ Request timeout setelah 10 detik');
              throw Exception('Request timeout');
            },
          );

      print('📡 Check Device Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final hasDevice = data['status'] == true;
        final deviceCount = data['data']?['connected_devices']?.length ?? 0;

        print('✅ Has Device: $hasDevice, Count: $deviceCount');

        return {
          'success': true,
          'hasConnectedDevice': hasDevice,
          'deviceCount': deviceCount,
          'devices': data['data']?['connected_devices'] ?? [],
          'message': data['message'] ?? '',
        };
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token invalid');
        return {
          'success': false,
          'hasConnectedDevice': false,
          'deviceCount': 0,
          'message': 'Token tidak valid',
        };
      } else {
        final error = json.decode(response.body);
        print('❌ API Error: ${error['message']}');
        return {
          'success': false,
          'hasConnectedDevice': false,
          'deviceCount': 0,
          'message': error['message'] ?? 'Gagal mengecek device',
        };
      }
    } on http.ClientException catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'hasConnectedDevice': false,
        'deviceCount': 0,
        'message': 'Tidak dapat terhubung ke server',
      };
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return {
        'success': false,
        'hasConnectedDevice': false,
        'deviceCount': 0,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
