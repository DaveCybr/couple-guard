import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/app_routes.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();

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

      _isInitialized = true;
      print('✅ Local Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Local Notification Service: $e');
      _isInitialized = false;
    }
  }

  /// Create notification channel untuk Android
  Future<void> _createNotificationChannel() async {
    try {
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

      print('✅ Notification channel created: geofence_alerts');
    } catch (e) {
      print('❌ Error creating notification channel: $e');
    }
  }

  /// Show geofence notification
  Future<void> showGeofenceNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (!_isInitialized) {
        print(
          '⚠️ Local Notification Service not initialized, initializing now...',
        );
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'geofence_alerts',
        'Geofence Alerts',
        channelDescription: 'Alerts when child leaves safe zone',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        autoCancel: true,
        timeoutAfter: 3600000, // 1 hour
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique ID based on timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: _encodePayload(data),
      );

      print('✅ Geofence notification shown: $title');
    } catch (e) {
      print('❌ Error showing geofence notification: $e');
    }
  }

  /// Show progress notification untuk monitoring commands
  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    required String channelId,
    required String channelName,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Create progress channel jika belum ada
      if (Platform.isAndroid) {
        await _createProgressChannel(channelId, channelName);
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Progress notifications',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        onlyAlertOnce: true,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        autoCancel: progress >= maxProgress,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1, // Fixed ID untuk progress notification
        title,
        body,
        details,
      );
    } catch (e) {
      print('❌ Error showing progress notification: $e');
    }
  }

  /// Create progress notification channel
  Future<void> _createProgressChannel(
    String channelId,
    String channelName,
  ) async {
    try {
      final channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Progress notifications',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('❌ Error creating progress channel: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('✅ Notification $id cancelled');
    } catch (e) {
      print('❌ Error cancelling notification $id: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🎯 Notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      final data = _decodePayload(response.payload!);
      _navigateToGeofenceDetail(data);
    }
  }

  /// Navigate to geofence detail
  void _navigateToGeofenceDetail(Map<String, dynamic> data) {
    print('📍 Navigating to geofence detail with data: $data');

    final type = data['type'];

    if (type == 'GEOFENCE_VIOLATION') {
      // Delay sedikit untuk memastikan navigator ready
      Future.delayed(Duration(milliseconds: 500), () {
        AppNavigator.navigatorKey.currentState?.pushNamed(
          AppRoutes.geofenceDetail,
          arguments: {
            'device_id': data['device_id'],
            'device_name': data['device_name'],
            'geofence_id': data['geofence_id'],
            'geofence_name': data['geofence_name'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'timestamp': data['timestamp'],
          },
        );
      });
    }
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> data) {
    try {
      return data.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
    } catch (e) {
      print('❌ Error encoding payload: $e');
      return '';
    }
  }

  /// Decode payload from string
  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final map = <String, dynamic>{};
      for (var pair in payload.split('&')) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          map[parts[0]] = Uri.decodeComponent(parts[1]);
        }
      }
      return map;
    } catch (e) {
      print('❌ Error decoding payload: $e');
      return {};
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
