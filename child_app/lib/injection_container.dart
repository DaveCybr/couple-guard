// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/network_info.dart';
import 'core/platform/device_info.dart';
import 'core/security/encryption_service.dart';
import 'core/storage/local_database.dart';
import 'core/storage/preferences_service.dart';

// Services
import 'services/background_service.dart';
import 'services/heartbeat_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

// Location Tracking Feature
import 'features/location_tracking/data/datasources/location_local_datasource.dart';
import 'features/location_tracking/data/datasources/location_remote_datasource.dart';
import 'features/location_tracking/data/repositories/location_repository_impl.dart';
import 'features/location_tracking/domain/repositories/location_repository.dart';
import 'features/location_tracking/domain/usecases/start_location_tracking.dart';
import 'features/location_tracking/domain/usecases/stop_location_tracking.dart';
import 'features/location_tracking/domain/usecases/get_current_location.dart';
import 'features/location_tracking/domain/usecases/upload_location.dart';
import 'features/location_tracking/presentation/bloc/location_bloc.dart';

// Authentication Feature
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/sign_in_anonymously.dart';
import 'features/authentication/domain/usecases/sign_out.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';

// Device Monitoring Feature
import 'features/device_monitoring/data/datasources/device_local_datasource.dart';
import 'features/device_monitoring/data/datasources/device_remote_datasource.dart';
import 'features/device_monitoring/data/repositories/device_repository_impl.dart';
import 'features/device_monitoring/domain/repositories/device_repository.dart';
import 'features/device_monitoring/domain/usecases/monitor_device.dart';
import 'features/device_monitoring/presentation/bloc/device_bloc.dart';

// Settings Feature
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Location Tracking
  // Bloc
  sl.registerFactory(() => LocationBloc(
    startTracking: sl(),
    stopTracking: sl(),
    getCurrentLocation: sl(),
    uploadLocation: sl(),
    repository: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => StartLocationTracking(sl()));
  sl.registerLazySingleton(() => StopLocationTracking(sl()));
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => UploadLocation(sl()));

  // Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      deviceInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(database: sl()),
  );

  //! Features - Authentication
  // Bloc
  sl.registerFactory(() => AuthBloc(
    signInAnonymously: sl(),
    signOut: sl(),
    repository: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(preferences: sl()),
  );

  //! Features - Device Monitoring
  // Bloc
  sl.registerFactory(() => DeviceBloc(
    monitorDevice: sl(),
    repository: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => MonitorDevice(sl()));

  // Repository
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      deviceInfo: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<DeviceLocalDataSource>(
    () => DeviceLocalDataSourceImpl(
      database: sl(),
      preferences: sl(),
    ),
  );

  //! Features - Settings
  // Bloc
  sl.registerFactory(() => SettingsBloc(
    getSettings: sl(),
    updateSettings: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateSettings(sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(
      preferences: sl(),
      database: sl(),
    ),
  );

  //! Services
  sl.registerLazySingleton(() => BackgroundService());
  sl.registerLazySingleton(() => HeartbeatService(
    firestore: sl(),
    deviceInfo: sl(),
    networkInfo: sl(),
  ));
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => SyncService(
    locationRepository: sl(),
    deviceRepository: sl(),
    networkInfo: sl(),
  ));

  //! Core
  sl.registerLazySingleton(() => NetworkInfo());
  sl.registerLazySingleton(() => DeviceInfo());
  sl.registerLazySingleton(() => EncryptionService()..initialize());
  sl.registerLazySingleton(() => LocalDatabase());
  sl.registerLazySingleton(() => PreferencesService(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => Connectivity());
}

// core/storage/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Child ID
  Future<void> setChildId(String childId) async {
    try {
      await _prefs.setString(AppConstants.kChildId, childId);
    } catch (e) {
      AppLogger.error('Failed to set child ID', e);
    }
  }

  String? getChildId() {
    try {
      return _prefs.getString(AppConstants.kChildId);
    } catch (e) {
      AppLogger.error('Failed to get child ID', e);
      return null;
    }
  }

  // Parent ID
  Future<void> setParentId(String parentId) async {
    try {
      await _prefs.setString(AppConstants.kParentId, parentId);
    } catch (e) {
      AppLogger.error('Failed to set parent ID', e);
    }
  }

  String? getParentId() {
    try {
      return _prefs.getString(AppConstants.kParentId);
    } catch (e) {
      AppLogger.error('Failed to get parent ID', e);
      return null;
    }
  }

  // Device ID
  Future<void> setDeviceId(String deviceId) async {
    try {
      await _prefs.setString(AppConstants.kDeviceId, deviceId);
    } catch (e) {
      AppLogger.error('Failed to set device ID', e);
    }
  }

  String? getDeviceId() {
    try {
      return _prefs.getString(AppConstants.kDeviceId);
    } catch (e) {
      AppLogger.error('Failed to get device ID', e);
      return null;
    }
  }

  // First launch
  Future<void> setFirstLaunch(bool isFirst) async {
    try {
      await _prefs.setBool(AppConstants.kFirstLaunch, isFirst);
    } catch (e) {
      AppLogger.error('Failed to set first launch', e);
    }
  }

  bool isFirstLaunch() {
    try {
      return _prefs.getBool(AppConstants.kFirstLaunch) ?? true;
    } catch (e) {
      AppLogger.error('Failed to get first launch', e);
      return true;
    }
  }

  // Settings
  Future<void> setAppSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs.setString(AppConstants.kAppSettings, json.encode(settings));
    } catch (e) {
      AppLogger.error('Failed to set app settings', e);
    }
  }

  Map<String, dynamic> getAppSettings() {
    try {
      final settingsString = _prefs.getString(AppConstants.kAppSettings);
      if (settingsString != null) {
        return json.decode(settingsString) as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    } catch (e) {
      AppLogger.error('Failed to get app settings', e);
      return <String, dynamic>{};
    }
  }

  // User token
  Future<void> setUserToken(String token) async {
    try {
      await _prefs.setString(AppConstants.kUserToken, token);
    } catch (e) {
      AppLogger.error('Failed to set user token', e);
    }
  }

  String? getUserToken() {
    try {
      return _prefs.getString(AppConstants.kUserToken);
    } catch (e) {
      AppLogger.error('Failed to get user token', e);
      return null;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
      AppLogger.info('All preferences cleared');
    } catch (e) {
      AppLogger.error('Failed to clear preferences', e);
    }
  }
}

// services/sync_service.dart
import 'dart:async';
import '../core/network/network_info.dart';
import '../core/utils/logger.dart';
import '../features/location_tracking/domain/repositories/location_repository.dart';
import '../features/device_monitoring/domain/repositories/device_repository.dart';

class SyncService {
  final LocationRepository _locationRepository;
  final DeviceRepository _deviceRepository;
  final NetworkInfo _networkInfo;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required LocationRepository locationRepository,
    required DeviceRepository deviceRepository,
    required NetworkInfo networkInfo,
  }) : _locationRepository = locationRepository,
       _deviceRepository = deviceRepository,
       _networkInfo = networkInfo;

  Future<void> startPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await syncAllData();
    });

    // Initial sync
    await syncAllData();
    AppLogger.info('Periodic sync started');
  }

  Future<void> syncAllData() async {
    if (_isSyncing) {
      AppLogger.debug('Sync already in progress, skipping');
      return;
    }

    if (!await _networkInfo.isConnected) {
      AppLogger.debug('No network connection, skipping sync');
      return;
    }

    _isSyncing = true;
    try {
      AppLogger.info('Starting data sync');

      // Sync cached locations
      await _syncCachedLocations();

      // Sync device data
      await _syncDeviceData();

      AppLogger.info('Data sync completed successfully');
    } catch (e) {
      AppLogger.error('Data sync failed', e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCachedLocations() async {
    try {
      final cachedResult = await _locationRepository.getCachedLocations();
      cachedResult.fold(
        (failure) {
          AppLogger.error('Failed to get cached locations: ${failure.message}');
        },
        (locations) async {
          AppLogger.info('Syncing ${locations.length} cached locations');
          
          for (final location in locations) {
            final uploadResult = await _locationRepository.uploadLocation(location);
            uploadResult.fold(
              (failure) => AppLogger.error('Failed to sync location: ${failure.message}'),
              (_) => AppLogger.debug('Location synced: ${location.id}'),
            );
          }

          if (locations.isNotEmpty) {
            await _locationRepository.clearCachedLocations();
            AppLogger.info('Cached locations cleared after sync');
          }
        },
      );
    } catch (e) {
      AppLogger.error('Error syncing cached locations', e);
    }
  }

  Future<void> _syncDeviceData() async {
    try {
      // Get cached device data and sync
      final cachedResult = await _deviceRepository.getCachedDeviceData();
      cachedResult.fold(
        (failure) {
          AppLogger.error('Failed to get cached device data: ${failure.message}');
        },
        (deviceDataList) async {
          AppLogger.info('Syncing ${deviceDataList.length} cached device data');
          
          for (final deviceData in deviceDataList) {
            final uploadResult = await _deviceRepository.uploadDeviceData(deviceData);
            uploadResult.fold(
              (failure) => AppLogger.error('Failed to sync device data: ${failure.message}'),
              (_) => AppLogger.debug('Device data synced: ${deviceData.id}'),
            );
          }

          if (deviceDataList.isNotEmpty) {
            await _deviceRepository.clearCachedDeviceData();
            AppLogger.info('Cached device data cleared after sync');
          }
        },
      );
    } catch (e) {
      AppLogger.error('Error syncing device data', e);
    }
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    AppLogger.info('Periodic sync stopped');
  }

  void dispose() {
    stopPeriodicSync();
  }
}

// services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidInitializationSettings = AndroidInitializationSettings('app_icon');
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createNotificationChannels();
      
      _isInitialized = true;
      AppLogger.info('Notification service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize notification service', e);
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        AppConstants.kLocationChannel,
        'Location Tracking',
        description: 'Notifications about location tracking status',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        AppConstants.kAlertChannel,
        'Safety Alerts',
        description: 'Important safety and emergency alerts',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        AppConstants.kGeneralChannel,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in channels) {
      await androidImplementation?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTap(NotificationResponse notificationResponse) {
    AppLogger.info('Notification tapped: ${notificationResponse.payload}');
    
    // Handle notification tap based on payload
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
      // This could trigger navigation events or other actions
    }
  }

  Future<void> showLocationTrackingNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidNotificationDetails = AndroidNotificationDetails(
      AppConstants.kLocationChannel,
      'Location Tracking',
      channelDescription: 'Location tracking notifications',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: 'app_icon',
    );

    const iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // Location tracking notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showSafetyAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidNotificationDetails = AndroidNotificationDetails(
      AppConstants.kAlertChannel,
      'Safety Alerts',
      channelDescription: 'Important safety alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Safety Alert',
      icon: 'alert_icon',
      color: Color(0xFFFF0000), // Red color for alerts
    );

    const iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alert_sound.aiff',
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      2, // Safety alert notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidNotificationDetails = AndroidNotificationDetails(
      AppConstants.kGeneralChannel,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'app_icon',
    );

    const iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      3, // General notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<bool> requestPermissions() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    final iosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.requestPermission() ?? false;
    }

    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return false;
  }
}

// core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF0056F1);
  static const Color primaryLight = Color(0xFF4285F4);
  static const Color primaryDark = Color(0xFF003A9F);

  // Secondary colors
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF4DD0E1);
  static const Color secondaryDark = Color(0xFF00838F);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);

  // Grey scale
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);

  // Special colors
  static const Color tracking = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color emergency = Color(0xFFD32F2F);
  static const Color geofence = Color(0xFF9C27B0);
}

// core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Special styles
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Colors.grey,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: Colors.grey,
  );
}

// core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.surface,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        headlineSmall: AppTextStyles.h5,
        titleLarge: AppTextStyles.h6,
        titleMedium: AppTextStyles.labelLarge,
        titleSmall: AppTextStyles.labelMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.grey[850],
      ),

      // Similar styling for dark theme...
      // (continuing with dark theme colors)
    );
  }
}