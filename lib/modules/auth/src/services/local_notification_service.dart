import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/app_routes.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel untuk Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    print('✅ Local Notification Service initialized');
  }

  /// Create notification channel
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'geofence_alerts', // ID
      'Geofence Alerts', // Name
      description: 'Alerts when child leaves safe zone',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Show geofence notification
  Future<void> showGeofenceNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'geofence_alerts',
      'Geofence Alerts',
      channelDescription: 'Alerts when child leaves safe zone',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: _encodePayload(data),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _navigateToGeofenceDetail(data);
    }
  }

  /// Navigate to geofence detail
  void _navigateToGeofenceDetail(Map<String, dynamic> data) {
    print('📍 Notification tapped - Data: $data');

    if (data['type'] == 'GEOFENCE_VIOLATION') {
      AppNavigator.navigatorKey.currentState?.pushNamed(
        AppRoutes.geofenceDetail, // ← Sesuaikan route
        arguments: data,
      );
    }
  }

  /// Encode payload
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (var pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }
}
