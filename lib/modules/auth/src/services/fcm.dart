import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/local_notification_service.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Background handler harus top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');

  // Initialize services
  await Firebase.initializeApp();

  // Initialize local notification service
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();

  // Process the message
  await _processBackgroundMessage(message, localNotificationService);
}

// Process background message
Future<void> _processBackgroundMessage(
  RemoteMessage message,
  LocalNotificationService localNotificationService,
) async {
  try {
    print('📦 Background message data: ${message.data}');
    print('📝 Background notification: ${message.notification}');

    // Show local notification
    await localNotificationService.showGeofenceNotification(
      title: message.notification?.title ?? 'Geofence Alert',
      body: message.notification?.body ?? 'Device left safe zone',
      data: message.data,
    );

    print('✅ Background notification processed successfully');
  } catch (e) {
    print('❌ Error processing background message: $e');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize FCM Service
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print('⚠️ FCM Service already initialized');
        return;
      }

      // Request permissions
      await _requestPermission();

      // Initialize local notification service
      await _localNotificationService.initialize();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Configure FCM settings
      await _configureFCM();

      _isInitialized = true;
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM Service: $e');
      _isInitialized = false;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS permission
        NotificationSettings settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        print(
          '📱 iOS Notification permission: ${settings.authorizationStatus}',
        );
      } else if (Platform.isAndroid) {
        // Android 13+ permission
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }
        print('📱 Android Notification permission: $status');
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
    }
  }

  /// Configure FCM settings
  Future<void> _configureFCM() async {
    try {
      // Set foreground presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, // Show alert when in foreground
        badge: true, // Update badge when in foreground
        sound: true, // Play sound when in foreground
      );

      // Subscribe to topics if needed
      // await _fcm.subscribeToTopic('geofence_alerts');

      print('✅ FCM configuration completed');
    } catch (e) {
      print('❌ Error configuring FCM: $e');
    }
  }

  /// Get FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _fcm.getToken();

      if (_fcmToken != null) {
        print('🔑 FCM Token: $_fcmToken');

        // Save token to shared preferences
        await _saveFCMToken(_fcmToken!);

        // Send token to backend
        await _sendTokenToBackend(_fcmToken!);
      } else {
        print('⚠️ FCM Token is null');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');

        // Save new token
        await _saveFCMToken(newToken);

        // Send new token to backend
        await _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to shared preferences
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('💾 FCM Token saved to shared preferences');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to your backend
      // Example:
      // await ApiService().updateFCMToken(token);

      print('📡 FCM Token sent to backend: $token');
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // 1. Foreground messages (app terbuka)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. Background messages (app di background/terminated)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Handle notification taps
    _handleNotificationTaps();

    print('✅ FCM message handlers setup completed');
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
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

      // You can also show in-app dialog or update UI here
      _showInAppNotification(message);
    } catch (e) {
      print('❌ Error handling foreground message: $e');
    }
  }

  /// Show in-app notification (optional)
  void _showInAppNotification(RemoteMessage message) {
    // TODO: Implement in-app notification system jika diperlukan
    // Contoh: showDialog atau update state di provider
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
    print('📍 Navigating to geofence detail with data: $data');

    final type = data['type'];

    if (type == 'GEOFENCE_VIOLATION') {
      // Delay untuk memastikan navigator ready
      Future.delayed(Duration(milliseconds: 500), () {
        try {
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
          print('✅ Navigation to geofence detail completed');
        } catch (e) {
          print('❌ Error navigating to geofence detail: $e');
        }
      });
    }
  }

  /// Delete FCM token (untuk logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _fcmToken = null;

      // Remove from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      // TODO: Notify backend about token deletion

      print('🗑️ FCM token deleted successfully');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }

    // Try to get from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_token');
      return _fcmToken;
    } catch (e) {
      print('❌ Error getting FCM token from storage: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Test FCM connectivity
  Future<bool> testFCMConnection() async {
    try {
      final token = await getCurrentToken();
      if (token == null) {
        print('❌ FCM Test: No token available');
        return false;
      }

      print('✅ FCM Test: Token available - ${token.substring(0, 20)}...');
      return true;
    } catch (e) {
      print('❌ FCM Test failed: $e');
      return false;
    }
  }
}
