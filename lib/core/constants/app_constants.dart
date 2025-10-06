class AppConstants {
  // App Info
  static const String appName = 'Parental Control';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Keluarga aman, terkendali, dan terhubung.';

  // API Configuration
  static const String baseUrl = 'https://api.coupleguard.com';
  static const String apiVersion = 'v1';
  static const String fullApiUrl = '$baseUrl/api/$apiVersion';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String notificationKey = 'notifications_enabled';

  // Location Settings
  static const int locationUpdateInterval = 30; // seconds
  static const int locationHistoryDays = 14;
  static const double geofenceDefaultRadius = 100.0; // meters
  static const double geofenceMinRadius = 50.0; // meters
  static const double geofenceMaxRadius = 5000.0; // meters

  // Monitoring Settings
  static const int screenCaptureInterval = 60; // seconds
  static const int maxScreenCaptureSize = 5 * 1024 * 1024; // 5MB
  static const int cameraSessionTimeout = 300; // 5 minutes

  // UI Settings
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Network Settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;
  static const int maxPhoneLength = 15;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi'];
}

enum AppState { initial, loading, success, error, noInternet }

enum UserRole { monitor, monitored }

enum CoupleStatus { pending, active, paused, terminated }

enum LocationAccuracy { lowest, low, medium, high, best }

enum NotificationType { location, geofence, security, system, app }
