import 'dart:convert';
import 'package:couple_guard/core/configs/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  final String _baseUrl = ApiConfig.baseUrl; // ganti sesuai URL backend

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {
        'Content-Type': 'application/json', // Tambahkan header
        'Accept': 'application/json',
      },
      body: jsonEncode({
        // Gunakan jsonEncode untuk konsistensi
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Asumsikan API mengembalikan data user di field 'user'
      return UserModel.fromJson({
        ...responseData['user'],
        'token': responseData['token'], // 🔹 inject token ke dalam user
      });
      // ATAU jika data user langsung di root level:
      // return UserModel.fromJson(responseData);
    } else {
      throw Exception("Login gagal: ${response.body}");
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final body = {
      "name": name,
      "email": email,
      "password": password,
      "role": role,
    };

    if (phone != null && phone.isNotEmpty) {
      body["phone"] = phone;
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/auth/register"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      // Inject token juga ke UserModel
      return UserModel.fromJson({
        ...responseData['user'],
        'token': responseData['token'], // 🔹 simpan token dari response
      });
    } else {
      throw Exception("Register gagal: ${response.body}");
    }
  }

  Future<UserModel?> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/auth/me"), // atau /user/profile
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Asumsikan API mengembalikan user data langsung atau di field 'user'
        if (responseData.containsKey('user')) {
          return UserModel.fromJson(responseData['user']);
        } else {
          return UserModel.fromJson(responseData);
        }
      } else if (response.statusCode == 401) {
        // Token expired atau invalid
        return null;
      } else {
        throw Exception("Failed to get user data: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Get current user error: $e");
      return null;
    }
  }

  /// Logout - invalidate token di server
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
      throw Exception("Logout API failed: ${response.body}");
    }
  }

  /// Refresh token (jika API mendukung)
  Future<String?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/refresh"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['access_token'] ?? responseData['token'];
      } else {
        return null;
      }
    } catch (e) {
      throw Exception("Refresh token error: $e");
      return null;
    }
  }

  /// Verify email (jika ada fitur email verification)
  Future<bool> verifyEmail(String token, String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/verify-email"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'verification_code': verificationCode}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Verify email error: $e");
      return false;
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification(String token) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/resend-verification"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Resend verification error: $e");
      return false;
    }
  }

  /// Update user profile
  Future<UserModel?> updateProfile(
    String token,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/user/profile"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('user')) {
          return UserModel.fromJson(responseData['user']);
        } else {
          return UserModel.fromJson(responseData);
        }
      } else {
        throw Exception("Failed to update profile: ${response.body}");
      }
    } catch (e) {
      throw Exception("Update profile error: $e");
      return null;
    }
  }

  /// Change password
  Future<bool> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/auth/change-password"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Change password error: $e");
      return false;
    }
  }
}
