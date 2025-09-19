// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.100.39:8000/api';
  static const String wsUrl = 'wss://api.coupleguard.app/ws';
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';
  static const String authUser = '/auth/user';

  // Partner endpoints
  static const String partnerInvite = '/partners/invite';
  static const String partnerAccept = '/partners/accept';
  static const String partnerConsent = '/consent/request';

  // Location endpoints
  static const String locationUpdate = '/location/update';
  static const String locationHistory = '/location/history';

  // Monitoring endpoints
  static const String monitoringCamera = '/monitor/camera/start';
  static const String monitoringScreen = '/monitor/screen/capture';
}
