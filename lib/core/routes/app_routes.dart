class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Family Code Screen (New)
  static const String familyCode = '/family-code';

  // Main Routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static const String family = '/family';

  // Location Routes
  static const String location = '/location';
  static const String locationHistory = '/location/history';
  static const String geofences = '/geofences';
  static const String addGeofence = '/geofences/add';
  static const String editGeofence = '/geofences/edit';

  // Monitoring Routes
  static const String monitoring = '/monitoring';
  static const String screenMirroring = '/monitoring/screen';
  static const String cameraAccess = '/monitoring/camera';
  static const String deviceInfo = '/monitoring/device';

  // Couple Routes
  static const String coupleInvite = '/couple/invite';
  static const String coupleAccept = '/couple/accept';
  static const String coupleSettings = '/couple/settings';

  // Notification Routes
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
}
