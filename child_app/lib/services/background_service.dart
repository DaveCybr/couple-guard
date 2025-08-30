// services/background_service.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';
import '../injection_container.dart' as di;

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String _notificationChannelId = 'safekids_tracking';
  static const String _notificationChannelName = 'Location Tracking';
  static const int _notificationId = 888;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final service = FlutterBackgroundService();
      
      // Configure notifications
      await _configureNotifications();

      // Initialize background service
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: 'SafeKids Protection Active',
          initialNotificationContent: 'Keeping your child safe',
          foregroundServiceNotificationId: _notificationId,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      _isInitialized = true;
      AppLogger.info('Background service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize background service', e);
      rethrow;
    }
  }

  Future<void> _configureNotifications() async {
    const androidInitializationSettings = AndroidInitializationSettings('app_icon');
    const iosInitializationSettings = DarwinInitializationSettings();
    
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channel for Android
    const androidNotificationChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'This channel is used for location tracking notifications',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    AppLogger.info('iOS background service triggered');
    return true;
  }

  static void onStart(ServiceInstance service) async {
    AppLogger.info('Background service started');
    
    // Initialize dependencies in isolate
    await di.init();

    Timer.periodic(const Duration(minutes: 10), (timer) async {
      try {
        await _performLocationUpdate(service);
      } catch (e) {
        AppLogger.error('Background location update failed', e);
      }
    });

    Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        await _sendHeartbeat(service);
      } catch (e) {
        AppLogger.error('Background heartbeat failed', e);
      }
    });

    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _checkBatteryLevel(service);
      } catch (e) {
        AppLogger.error('Background battery check failed', e);
      }
    });

    // Listen for service stop
    service.on('stopService').listen((event) {
      AppLogger.info('Background service stopping');
      service.stopSelf();
    });
  }

  static Future<void> _performLocationUpdate(ServiceInstance service) async {
    try {
      final locationRepository = di.sl<LocationRepository>();
      final result = await locationRepository.getCurrentLocation();
      
      result.fold(
        (failure) {
          AppLogger.error('Background location failed: ${failure.message}');
          service.invoke('location_error', {'error': failure.message});
        },
        (location) async {
          await locationRepository.uploadLocation(location);
          service.invoke('location_updated', {
            'lat': location.latitude,
            'lng': location.longitude,
            'timestamp': location.timestamp.toIso8601String(),
          });
          
          // Update notification
          await _updateNotification(
            'Location Updated',
            'Last update: ${DateTime.now().toString().substring(11, 16)}',
          );
        },
      );
    } catch (e) {
      AppLogger.error('Background location update error', e);
    }
  }

  static Future<void> _sendHeartbeat(ServiceInstance service) async {
    try {
      final heartbeatService = di.sl<HeartbeatService>();
      await heartbeatService.sendHeartbeat();
      
      service.invoke('heartbeat_sent', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Background heartbeat error', e);
    }
  }

  static Future<void> _checkBatteryLevel(ServiceInstance service) async {
    try {
      final deviceInfo = di.sl<DeviceInfo>();
      final batteryLevel = await deviceInfo.getBatteryLevel();
      
      service.invoke('battery_updated', {
        'level': batteryLevel,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Show low battery warning
      if (batteryLevel <= 20) {
        await _updateNotification(
          'Low Battery Warning',
          'Battery: $batteryLevel% - Consider charging',
        );
      }
    } catch (e) {
      AppLogger.error('Background battery check error', e);
    }
  }

  static Future<void> _updateNotification(String title, String content) async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidNotificationDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: 'SafeKids location tracking',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        icon: 'app_icon',
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        _notificationId,
        title,
        content,
        notificationDetails,
      );
    } catch (e) {
      AppLogger.error('Failed to update notification', e);
    }
  }

  Future<void> startService() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    
    if (!isRunning) {
      await service.startService();
      AppLogger.info('Background service started manually');
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    AppLogger.info('Background service stop requested');
  }
}

// services/heartbeat_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/platform/device_info.dart';
import '../core/network/network_info.dart';
import '../core/utils/logger.dart';

class HeartbeatService {
  final FirebaseFirestore _firestore;
  final DeviceInfo _deviceInfo;
  final NetworkInfo _networkInfo;
  
  Timer? _heartbeatTimer;
  String? _childId;

  HeartbeatService({
    required FirebaseFirestore firestore,
    required DeviceInfo deviceInfo,
    required NetworkInfo networkInfo,
  }) : _firestore = firestore,
       _deviceInfo = deviceInfo,
       _networkInfo = networkInfo;

  Future<void> initialize(String childId) async {
    _childId = childId;
    await startHeartbeat();
    AppLogger.info('Heartbeat service initialized for child: $childId');
  }

  Future<void> startHeartbeat() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await sendHeartbeat();
    });
    
    // Send initial heartbeat
    await sendHeartbeat();
  }

  Future<void> sendHeartbeat() async {
    if (_childId == null) return;

    try {
      final deviceDetails = await _deviceInfo.getDeviceDetails();
      final networkType = await _networkInfo.connectionType;
      final isConnected = await _networkInfo.isConnected;

      final heartbeatData = {
        'child_id': _childId,
        'status': 'alive',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'battery_level': deviceDetails['battery_level'] ?? 0,
        'network': networkType,
        'is_connected': isConnected,
        'device_info': {
          'model': deviceDetails['model'],
          'os_version': deviceDetails['os_version'],
          'app_version': deviceDetails['app_version'],
        },
        'last_activity': DateTime.now().toUtc().toIso8601String(),
      };

      await _firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(_childId)
          .collection('heartbeat')
          .doc(AppConstants.kCurrentStatus)
          .set(heartbeatData, SetOptions(merge: true));

      AppLogger.debug('Heartbeat sent successfully');
    } catch (e) {
      AppLogger.error('Failed to send heartbeat', e);
    }
  }

  Future<void> sendAppStateUpdate(String state) async {
    if (_childId == null) return;

    try {
      final deviceDetails = await _deviceInfo.getDeviceDetails();
      
      final stateData = {
        'child_id': _childId,
        'app_state': state,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'battery_level': deviceDetails['battery_level'] ?? 0,
        'device_info': deviceDetails,
      };

      await _firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(_childId)
          .collection('app_events')
          .add(stateData);

      AppLogger.info('App state update sent: $state');
    } catch (e) {
      AppLogger.error('Failed to send app state update', e);
    }
  }

  Future<void> sendEmergencySignal({
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    if (_childId == null) return;

    try {
      final deviceDetails = await _deviceInfo.getDeviceDetails();
      
      final emergencyData = {
        'child_id': _childId,
        'type': 'emergency',
        'latitude': latitude,
        'longitude': longitude,
        'message': message ?? 'Emergency signal activated',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'device_info': deviceDetails,
        'priority': 'critical',
      };

      // Send to multiple locations for redundancy
      final futures = <Future>[];
      
      // Emergency collection
      futures.add(
        _firestore
            .collection(AppConstants.kChildrenCollection)
            .doc(_childId)
            .collection('emergency')
            .add(emergencyData),
      );
      
      // Alert parents collection
      futures.add(
        _firestore
            .collection(AppConstants.kAlertsCollection)
            .add(emergencyData),
      );
      
      // Update current status
      futures.add(
        _firestore
            .collection(AppConstants.kChildrenCollection)
            .doc(_childId)
            .collection('latest')
            .doc('emergency')
            .set(emergencyData, SetOptions(merge: true)),
      );

      await Future.wait(futures);
      AppLogger.info('Emergency signal sent successfully');
    } catch (e) {
      AppLogger.error('Failed to send emergency signal', e);
      rethrow;
    }
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    AppLogger.info('Heartbeat service stopped');
  }

  void dispose() {
    stopHeartbeat();
  }
}

// core/platform/device_info.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/logger.dart';

class DeviceInfo {
  static final DeviceInfo _instance = DeviceInfo._internal();
  factory DeviceInfo() => _instance;
  DeviceInfo._internal();

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Battery _battery = Battery();
  
  Map<String, dynamic>? _cachedDeviceInfo;
  DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  Future<Map<String, dynamic>> getDeviceDetails() async {
    // Return cached data if still valid
    if (_cachedDeviceInfo != null && 
        _lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!) < _cacheTimeout) {
      return _cachedDeviceInfo!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final batteryLevel = await getBatteryLevel();
      
      Map<String, dynamic> deviceData = {
        'app_name': packageInfo.appName,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'battery_level': batteryLevel,
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData.addAll({
          'device_id': androidInfo.id,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'os_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'is_physical_device': androidInfo.isPhysicalDevice,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData.addAll({
          'device_id': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'os_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        });
      }

      _cachedDeviceInfo = deviceData;
      _lastCacheTime = DateTime.now();
      
      return deviceData;
    } catch (e) {
      AppLogger.error('Failed to get device details', e);
      return {
        'error': 'Failed to get device info',
        'platform': Platform.operatingSystem,
        'battery_level': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
  }

  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      AppLogger.error('Failed to get battery level', e);
      return 0;
    }
  }

  Stream<BatteryState> get batteryStateStream => _battery.onBatteryStateChanged;

  Future<bool> isLowPowerMode() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        // Note: iOS doesn't provide direct access to low power mode
        // This is a placeholder for actual implementation
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to check low power mode', e);
      return false;
    }
  }

  Future<String> getUniqueDeviceId() async {
    try {
      final deviceDetails = await getDeviceDetails();
      return deviceDetails['device_id'] ?? 'unknown_device';
    } catch (e) {
      AppLogger.error('Failed to get device ID', e);
      return 'unknown_device';
    }
  }
}

// core/network/network_info.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class NetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;
  NetworkInfo._internal();

  final Connectivity _connectivity = Connectivity();
  
  StreamController<ConnectivityResult>? _connectivityController;
  ConnectivityResult? _lastResult;

  Stream<ConnectivityResult> get connectivityStream {
    _connectivityController ??= StreamController<ConnectivityResult>.broadcast();
    
    _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != _lastResult) {
        _lastResult = result;
        _connectivityController!.add(result);
        AppLogger.info('Network connectivity changed: ${result.name}');
      }
    });
    
    return _connectivityController!.stream;
  }

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLogger.error('Failed to check connectivity', e);
      return false;
    }
  }

  Future<String> get connectionType async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      switch (result) {
        case ConnectivityResult.wifi:
          return 'wifi';
        case ConnectivityResult.mobile:
          return 'mobile';
        case ConnectivityResult.ethernet:
          return 'ethernet';
        case ConnectivityResult.bluetooth:
          return 'bluetooth';
        case ConnectivityResult.vpn:
          return 'vpn';
        case ConnectivityResult.other:
          return 'other';
        case ConnectivityResult.none:
        default:
          return 'none';
      }
    } catch (e) {
      AppLogger.error('Failed to get connection type', e);
      return 'unknown';
    }
  }

  Future<bool> isWifiConnected() async {
    final type = await connectionType;
    return type == 'wifi';
  }

  Future<bool> isMobileConnected() async {
    final type = await connectionType;
    return type == 'mobile';
  }

  void dispose() {
    _connectivityController?.close();
    _connectivityController = null;
  }
}

// core/security/encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../utils/logger.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final Encrypter _encrypter;
  late final IV _iv;
  
  static const String _keyString = 'SafeKidsApp2024SecureLocationTracking'; // 32 chars
  
  void initialize() {
    try {
      final key = Key.fromBase64(base64Encode(_keyString.codeUnits));
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16);
      AppLogger.info('Encryption service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize encryption service', e);
      rethrow;
    }
  }

  String encryptString(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      AppLogger.error('Failed to encrypt string', e);
      return plainText; // Return plain text as fallback
    }
  }

  String decryptString(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      AppLogger.error('Failed to decrypt string', e);
      return encryptedText; // Return encrypted text as fallback
    }
  }

  Map<String, dynamic> encryptLocationData(Map<String, dynamic> data) {
    try {
      final sensitiveFields = ['lat', 'lng', 'latitude', 'longitude'];
      final encryptedData = Map<String, dynamic>.from(data);
      
      for (final field in sensitiveFields) {
        if (encryptedData.containsKey(field)) {
          final value = encryptedData[field].toString();
          encryptedData[field] = encryptString(value);
        }
      }
      
      encryptedData['encrypted'] = true;
      return encryptedData;
    } catch (e) {
      AppLogger.error('Failed to encrypt location data', e);
      return data; // Return original data as fallback
    }
  }

  Map<String, dynamic> decryptLocationData(Map<String, dynamic> data) {
    try {
      if (data['encrypted'] != true) {
        return data; // Not encrypted
      }
      
      final sensitiveFields = ['lat', 'lng', 'latitude', 'longitude'];
      final decryptedData = Map<String, dynamic>.from(data);
      
      for (final field in sensitiveFields) {
        if (decryptedData.containsKey(field)) {
          final encryptedValue = decryptedData[field].toString();
          final decryptedValue = decryptString(encryptedValue);
          decryptedData[field] = double.tryParse(decryptedValue) ?? 0.0;
        }
      }
      
      decryptedData.remove('encrypted');
      return decryptedData;
    } catch (e) {
      AppLogger.error('Failed to decrypt location data', e);
      return data; // Return original data as fallback
    }
  }

  String generateHash(String input) {
    try {
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.error('Failed to generate hash', e);
      return input;
    }
  }

  bool verifyHash(String input, String hash) {
    try {
      final computedHash = generateHash(input);
      return computedHash == hash;
    } catch (e) {
      AppLogger.error('Failed to verify hash', e);
      return false;
    }
  }
}

// core/storage/local_database.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/logger.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'safekids.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      AppLogger.error('Failed to initialize database', e);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Cached locations table
      await db.execute('''
        CREATE TABLE cached_locations (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          uploaded INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // App events table
      await db.execute('''
        CREATE TABLE app_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_type TEXT NOT NULL,
          data TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          synced INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Settings table
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX idx_cached_locations_timestamp ON cached_locations(timestamp)');
      await db.execute('CREATE INDEX idx_app_events_timestamp ON app_events(timestamp)');
      await db.execute('CREATE INDEX idx_cached_locations_uploaded ON cached_locations(uploaded)');

      AppLogger.info('Database tables created successfully');
    } catch (e) {
      AppLogger.error('Failed to create database tables', e);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from version $oldVersion to $newVersion');
    
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example migration
      // await db.execute('ALTER TABLE cached_locations ADD COLUMN new_field TEXT');
    }
  }

  Future<void> clearOldData() async {
    try {
      final db = await database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      // Clear old cached locations
      await db.delete(
        'cached_locations',
        where: 'timestamp < ? AND uploaded = 1',
        whereArgs: [thirtyDaysAgo],
      );
      
      // Clear old app events
      await db.delete(
        'app_events',
        where: 'timestamp < ? AND synced = 1',
        whereArgs: [thirtyDaysAgo],
      );
      
      AppLogger.info('Old data cleared from local database');
    } catch (e) {
      AppLogger.error('Failed to clear old data', e);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('Database closed');
    }
  }
}