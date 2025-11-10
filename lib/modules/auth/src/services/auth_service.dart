import 'dart:convert';
import 'package:couple_guard/core/configs/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      final parent = responseData['data']['parent'];
      final token = responseData['data']['token'];

      return UserModel.fromJson({...parent, "token": token});
    } else {
      throw Exception("Login gagal: ${response.body}");
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/register"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"email": email, "password": password}),
    );
    print('🔍 REGISTER RESPONSE: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      final parent = responseData['data']['parent'];
      final token = responseData['data']['token'];

      final user = UserModel.fromJson({...parent, "token": token});

      // Otomatis update FCM token dari FCMService
      try {
        // Import firebase_messaging di file ini
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null && fcmToken.isNotEmpty) {
          print('📤 Updating FCM token after register: $fcmToken');
          await updateFcmToken(fcmToken: fcmToken, token: token);
          print('✅ FCM token berhasil diupdate setelah register');
        } else {
          print('⚠️ FCM token tidak tersedia');
        }
      } catch (e) {
        print('⚠️ Gagal update FCM token setelah register: $e');
        // Tidak throw error agar registrasi tetap berhasil
      }

      return user;
    } else {
      throw Exception("Register gagal: ${response.body}");
    }
  }

  Future<UserModel?> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/auth/profile"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('🔍 CURRENT USER RESPONSE: ${response.body}');
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return UserModel.fromJson(responseData['data']);
    } else if (response.statusCode == 401) {
      return null;
    } else {
      throw Exception("Failed to get user data: ${response.statusCode}");
    }
  }

  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/logout"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Logout gagal: ${response.body}");
    }
  }

  Future<void> updateFcmToken({
    required String fcmToken,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/update-fcm-token"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"fcm_token": fcmToken}),
    );

    print('📡 UPDATE FCM RESPONSE: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅ FCM token updated successfully');
      } else {
        throw Exception("Update gagal: ${data['message'] ?? 'Unknown error'}");
      }
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: Token tidak valid atau kadaluarsa");
    } else {
      throw Exception(
        "Gagal update FCM token: ${response.statusCode} ${response.body}",
      );
    }
  }

  /// BARU: Ambil semua devices berdasarkan parent_id
  Future<List<DeviceModel>> getDevicesByParent({
    required int parentId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/devices/id_device/$parentId"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // DEBUG: Print response structure
      print('📱 Devices API Response:');
      print('Full response: $responseData');

      if (responseData['data'] is List) {
        List<dynamic> devicesJson = responseData['data'];

        // DEBUG: Print each device details
        for (var i = 0; i < devicesJson.length; i++) {
          print('--- Device $i ---');
          print('Full data: ${devicesJson[i]}');
          print('device_id: ${devicesJson[i]['device_id']}');
          print('device_id type: ${devicesJson[i]['device_id']?.runtimeType}');
          print('device_name: ${devicesJson[i]['device_name']}');
          print('is_online: ${devicesJson[i]['is_online']}');
        }

        return devicesJson
            .map((device) => DeviceModel.fromJson(device))
            .toList();
      } else {
        throw Exception("Invalid data format: expected List");
      }
    } else {
      throw Exception(
        "Gagal mengambil devices: ${response.statusCode} ${response.body}",
      );
    }
  }
}

// DeviceModel
class DeviceModel {
  final int? id; // Optional, hanya untuk reference
  final String deviceId; // Ini yang dipakai untuk notifikasi
  final String deviceName;
  final String deviceType;
  final bool isOnline;
  final String? lastSeen;

  DeviceModel({
    this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.isOnline,
    this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: _parseInt(json['id']),
      deviceId: json['device_id']?.toString() ?? '', // Pastikan String
      deviceName: json['device_name']?.toString() ?? '',
      deviceType: json['device_type']?.toString() ?? '',
      isOnline: json['is_online'] == true || json['is_online'] == 'true',
      lastSeen: json['last_seen']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
