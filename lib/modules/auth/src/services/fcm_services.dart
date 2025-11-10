import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/local_notification_service.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

// ← PENTING: Background handler harus top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.messageId}');
  // Firebase akan otomatis menampilkan notifikasi di system tray
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final AuthService _authService = AuthService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      print('✅ FCM Service initialized');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    try {
      // Request Android 13+ notification permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }
      }

      // Request FCM permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }

  /// Get FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();

      if (_fcmToken != null) {
        print('🔑 FCM Token: $_fcmToken');

        // Auto send token to backend if user is logged in
        await _sendTokenToBackend();
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // Auto send refreshed token to backend
        _sendTokenToBackend();
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Send token to backend
  Future<void> _sendTokenToBackend() async {
    if (_fcmToken == null) {
      print('⚠️ No FCM token to send');
      return;
    }

    try {
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) {
        print('⚠️ User not logged in, FCM token will be sent after login');
        return;
      }

      print('📤 Sending FCM token to backend...');
      await _authService.updateFcmToken(fcmToken: _fcmToken!, token: authToken);
      print('✅ FCM token sent to backend successfully');
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  /// BARU: Method untuk update FCM token setelah login/register
  Future<void> updateTokenAfterAuth(String authToken) async {
    if (_fcmToken == null) {
      print('⚠️ FCM token not available yet');
      return;
    }

    try {
      print('📤 Updating FCM token after authentication...');
      await _authService.updateFcmToken(fcmToken: _fcmToken!, token: authToken);
      print('✅ FCM token updated after authentication');
    } catch (e) {
      print('❌ Error updating FCM token after auth: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // 1. Foreground messages (app terbuka)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. Background messages (app di background/terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle notification taps
    _handleNotificationTaps();
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground message received: ${message.messageId}');
    print('📝 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');

    // Show local notification
    await _localNotificationService.showGeofenceNotification(
      title: message.notification?.title ?? 'Geofence Alert',
      body: message.notification?.body ?? 'Device left safe zone',
      data: message.data,
    );
  }

  /// Handle notification taps
  void _handleNotificationTaps() {
    // When app is terminated and opened via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🎯 App opened from terminated state via notification');
        _navigateToGeofenceDetail(message.data);
      }
    });

    // When app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🎯 App opened from background via notification');
      _navigateToGeofenceDetail(message.data);
    });
  }

  /// Navigate to geofence detail
  void _navigateToGeofenceDetail(Map<String, dynamic> data) {
    print('📍 Navigating to geofence detail: $data');

    final type = data['type'];

    if (type == 'GEOFENCE_VIOLATION') {
      // Navigate ke halaman detail geofence
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
    }
  }

  /// Delete FCM token (untuk logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _fcmToken = null;
      print('🗑️ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}
