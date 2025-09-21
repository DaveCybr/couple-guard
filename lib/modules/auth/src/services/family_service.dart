import 'dart:convert';
import 'package:couple_guard/modules/auth/src/models/family_model.dart';
import 'package:http/http.dart' as http;
import 'package:couple_guard/core/configs/api_config.dart';

class FamilyService {
  final String _baseUrl = ApiConfig.baseUrl; // ganti sesuai URL backend

  // 🔹 Create family
  Future<FamilyModel> createFamily({
    required String familyName,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: json.encode({'family_name': familyName}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FamilyModel.fromJson(data);
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw FamilyException(
          message: 'Validation error',
          errors: errorData['errors'],
          statusCode: response.statusCode,
        );
      } else {
        throw FamilyException(
          message: 'Failed to create family',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FamilyException) rethrow;
      throw FamilyException(message: 'Network error: ${e.toString()}');
    }
  }

  // 🔹 Get family members
  Future<List<GetFamily>> getFamilies({required String authToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['families'] != null) {
          final families = data['families'] as List;
          return families.map((f) => GetFamily.fromJson(f)).toList();
        } else {
          throw FamilyException(message: 'Invalid response format');
        }
      } else {
        throw FamilyException(
          message: 'Failed to fetch families',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FamilyException) rethrow;
      throw FamilyException(message: 'Network error: ${e.toString()}');
    }
  }

  Future<List<GetFamily>> getJoinedFamilies({required String authToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family/membersjoin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['families'] != null) {
          final families = data['families'] as List;
          return families.map((f) => GetFamily.fromJson(f)).toList();
        } else {
          throw FamilyException(message: 'Invalid response format');
        }
      } else {
        throw FamilyException(
          message: 'Failed to fetch joined families',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FamilyException) rethrow;
      throw FamilyException(message: 'Network error: ${e.toString()}');
    }
  }
}

class GetFamily {
  final int id;
  final String name;
  final String familyCode;

  GetFamily({required this.id, required this.name, required this.familyCode});

  factory GetFamily.fromJson(Map<String, dynamic> json) {
    return GetFamily(
      id: json['id'] as int,
      name: json['name'] as String,
      familyCode: json['family_code'] as String,
    );
  }
}

// Exception class
class FamilyException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  FamilyException({required this.message, this.errors, this.statusCode});

  @override
  String toString() {
    if (errors != null) {
      return 'FamilyException: $message - Errors: $errors';
    }
    return 'FamilyException: $message';
  }

  String getUserFriendlyMessage() {
    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }
    return message;
  }
}
