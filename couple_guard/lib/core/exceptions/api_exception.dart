// lib/core/exceptions/api_exception.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;

  ValidationException(String message, this.errors)
    : super(message, statusCode: 422);
}
