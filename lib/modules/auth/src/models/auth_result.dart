// lib/core/models/auth_result.dart
import 'user_model.dart';

class AuthResult {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? message;

  AuthResult({required this.success, this.token, this.user, this.message});
}
