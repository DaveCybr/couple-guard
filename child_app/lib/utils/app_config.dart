// App Config Constants
import 'dart:ui';

class AppConfig {
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const String pusherAppKey = 'your-pusher-app-key';
  static const String pusherCluster = 'your-pusher-cluster';

  // Location settings
  static const int locationUpdateIntervalMinutes = 30;
  static const int minimumDistanceFilter = 10; // meters
  static const int locationAccuracyThreshold = 100; // meters

  // Battery optimization
  static const int lowBatteryThreshold = 20;
  static const int criticalBatteryThreshold = 10;

  // Notification settings
  static const int notificationBatchSize = 10;
  static const int notificationBatchIntervalSeconds = 30;

  // Screen mirroring settings
  static const int screenshotQuality = 70;
  static const Size maxScreenshotSize = Size(720, 1280);
  static const int maxFpsForStreaming = 3;
}
