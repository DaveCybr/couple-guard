import 'dart:convert';
import 'package:couple_guard/core/configs/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

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

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      final parent = responseData['data']['parent'];
      final token = responseData['data']['token'];

      return UserModel.fromJson({...parent, "token": token});
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

  /// BARU: Ambil semua devices berdasarkan parent_id
  Future<List<DeviceModel>> getDevicesByParent({
    required int parentId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/devices/by-parent/$parentId"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      List<dynamic> devicesJson = responseData['data'];

      return devicesJson.map((device) => DeviceModel.fromJson(device)).toList();
    } else {
      throw Exception(
        "Gagal mengambil devices: ${response.statusCode} ${response.body}",
      );
    }
  }
}

// DeviceModel
class DeviceModel {
  final int id;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final bool isOnline;
  final String? lastSeen;

  DeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.isOnline,
    this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      isOnline: json['is_online'],
      lastSeen: json['last_seen'],
    );
  }
}
