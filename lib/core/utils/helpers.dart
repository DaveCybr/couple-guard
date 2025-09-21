// lib/core/constants/app_constants.dart
class AppConstants {
  // App Information
  static const String appName = 'CoupleGuard';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String onboardingCompleted = 'onboarding_completed';
  static const String biometricEnabled = 'biometric_enabled';
  static const String notificationEnabled = 'notification_enabled';

  // Permissions
  static const String locationPermission = 'location';
  static const String cameraPermission = 'camera';
  static const String microphonePermission = 'microphone';
  static const String notificationPermission = 'notification';

  // Location Settings
  static const int locationUpdateIntervalSeconds = 30;
  static const double geofenceMinRadius = 100.0; // meters
  static const double geofenceMaxRadius = 5000.0; // meters

  // Monitoring Settings
  static const int screenCaptureIntervalSeconds = 5;
  static const int maxLocationHistoryDays = 14;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

// // lib/core/services/notification_service.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications = 
//       FlutterLocalNotificationsPlugin();
//   static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

//   static Future<void> initialize() async {
//     // Local notifications
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     const settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notifications.initialize(settings);

//     // FCM
//     await _fcm.requestPermission();
//     final token = await _fcm.getToken();
//     debugPrint('FCM Token: $token');

//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//   }

//   static Future<void> showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'couple_guard_channel',
//       'CoupleGuard Notifications',
//       channelDescription: 'Notifications from CoupleGuard app',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const iosDetails = DarwinNotificationDetails();
//     const details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notifications.show(
//       DateTime.now().millisecond,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//   }

//   static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//     debugPrint('Background message: ${message.messageId}');
//   }

//   static void _handleForegroundMessage(RemoteMessage message) {
//     debugPrint('Foreground message: ${message.messageId}');
    
//     if (message.notification != null) {
//       showLocalNotification(
//         title: message.notification!.title ?? 'CoupleGuard',
//         body: message.notification!.body ?? '',
//       );
//     }
//   }
// }

// lib/main.dart