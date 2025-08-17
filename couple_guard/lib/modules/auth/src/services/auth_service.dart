// lib/core/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import '../config/api_config.dart';
import '../../../../core/configs/api_config.dart';
import '../../../../core/exceptions/api_exception.dart';
import '../models/auth_result.dart';
import '../models/user_model.dart';

class AuthService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResult(
          success: true,
          token: data['token'],
          user: UserModel.fromJson(data['user']),
        );
      } else {
        final error = jsonDecode(response.body);
        return AuthResult(
          success: false,
          message: error['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      throw ApiException('Network error during login: $e');
    }
  }

  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return AuthResult(success: true, message: 'Registration successful');
      } else {
        final error = jsonDecode(response.body);
        return AuthResult(
          success: false,
          message: error['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      throw ApiException('Network error during registration: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/user'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: await _getAuthHeaders(),
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    // Get token from secure storage
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _getStoredToken()}',
    };
  }

  Future<String?> _getStoredToken() async {
    // Implementation to get token from secure storage
    return null; // Placeholder
  }
}
