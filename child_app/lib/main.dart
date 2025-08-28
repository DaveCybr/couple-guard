// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'core/error/error_handler.dart';
import 'core/utils/logger.dart';
import 'injection_container.dart' as di;
import 'services/background_service.dart';

Future<void> main() async {
  await _initializeApp();
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling
  FlutterError.onError = (details) {
    AppLogger.error('Flutter Error', details.exception, details.stack);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  // Initialize Hydrated Bloc for state persistence
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  // Initialize dependency injection
  await di.init();

  // Initialize background service
  await BackgroundService().initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run app with error handling
  runZonedGuarded(
    () => runApp(const ParentalControlApp()),
    (error, stackTrace) {
      AppLogger.error('Unhandled Error', error, stackTrace);
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

// app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/navigation/app_router.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/location_tracking/presentation/bloc/location_bloc.dart';
import '../features/device_monitoring/presentation/bloc/device_bloc.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../injection_container.dart';

class ParentalControlApp extends StatelessWidget {
  const ParentalControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(AppStarted())),
        BlocProvider(create: (_) => sl<LocationBloc>()),
        BlocProvider(create: (_) => sl<DeviceBloc>()),
        BlocProvider(create: (_) => sl<SettingsBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'SafeKids - Parental Control',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('id', 'ID'),
            ],
            locale: settingsState.locale,
          );
        },
      ),
    );
  }
}

// app/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'SafeKids';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  // Environment configuration
  static const bool isProduction = kReleaseMode;
  static const bool isDebug = kDebugMode;
  
  // API Configuration
  static const String baseApiUrl = isProduction 
    ? 'https://api.safekids.com/v1'
    : 'https://staging-api.safekids.com/v1';
  
  // Firebase Configuration
  static const String firebaseProjectId = isProduction 
    ? 'safekids-prod'
    : 'safekids-staging';
  
  // Feature Flags
  static const bool enableAdvancedLocationTracking = true;
  static const bool enableScreenTimeMonitoring = true;
  static const bool enableGeofencing = true;
  static const bool enableEmergencyFeatures = true;
  static const bool enableAIContentFiltering = true;
  
  // Tracking Configuration
  static const Duration defaultLocationUpdateInterval = Duration(minutes: 10);
  static const Duration heartbeatInterval = Duration(minutes: 2);
  static const Duration batteryCheckInterval = Duration(minutes: 5);
  static const Duration syncInterval = Duration(minutes: 15);
  
  // Battery Optimization
  static const int lowBatteryThreshold = 20;
  static const int criticalBatteryThreshold = 10;
  
  // Geofencing
  static const double defaultGeofenceRadius = 100.0; // meters
  static const int maxGeofences = 10;
  
  // Data Retention
  static const Duration locationDataRetention = Duration(days: 90);
  static const Duration deviceDataRetention = Duration(days: 30);
  static const Duration logRetention = Duration(days: 7);
  
  // Security
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);
  
  // Compliance
  static const bool isGDPRCompliant = true;
  static const bool isCOPPACompliant = true;
  static const int minimumChildAge = 4;
  static const int maximumChildAge = 17;
}

// core/constants/app_constants.dart
class AppConstants {
  // Shared Preferences Keys
  static const String kUserToken = 'user_token';
  static const String kChildId = 'child_id';
  static const String kParentId = 'parent_id';
  static const String kDeviceId = 'device_id';
  static const String kFirstLaunch = 'first_launch';
  static const String kAppSettings = 'app_settings';
  
  // Collection Names
  static const String kChildrenCollection = 'children';
  static const String kParentsCollection = 'parents';
  static const String kLocationsCollection = 'locations';
  static const String kDevicesCollection = 'devices';
  static const String kGeofencesCollection = 'geofences';
  static const String kActivitiesCollection = 'activities';
  static const String kAlertsCollection = 'alerts';
  
  // Document Names
  static const String kLatestPosition = 'latest_position';
  static const String kCurrentStatus = 'current_status';
  static const String kDeviceInfo = 'device_info';
  static const String kSettings = 'settings';
  
  // Notification Channels
  static const String kLocationChannel = 'location_tracking';
  static const String kAlertChannel = 'safety_alerts';
  static const String kGeneralChannel = 'general_notifications';
  
  // Intent Actions
  static const String kLocationUpdateAction = 'com.safekids.LOCATION_UPDATE';
  static const String kEmergencyAction = 'com.safekids.EMERGENCY';
  static const String kGeofenceAction = 'com.safekids.GEOFENCE';
  
  // Error Codes
  static const String kNetworkError = 'NETWORK_ERROR';
  static const String kLocationError = 'LOCATION_ERROR';
  static const String kPermissionError = 'PERMISSION_ERROR';
  static const String kAuthError = 'AUTH_ERROR';
  static const String kDeviceError = 'DEVICE_ERROR';
}

// core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String code;
  final dynamic originalError;
  
  const Failure({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String code = 'NETWORK_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

class LocationFailure extends Failure {
  const LocationFailure({
    required String message,
    String code = 'LOCATION_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String code = 'PERMISSION_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String code = 'AUTH_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String code = 'CACHE_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

class DeviceFailure extends Failure {
  const DeviceFailure({
    required String message,
    String code = 'DEVICE_ERROR',
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

// core/utils/logger.dart
import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 3,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
    developer.log(
      message,
      name: 'SafeKids',
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error, stackTrace);
    developer.log(
      message,
      name: 'SafeKids',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
    developer.log(
      message,
      name: 'SafeKids',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    FirebaseCrashlytics.instance.log(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
    developer.log(
      message,
      name: 'SafeKids',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error, stackTrace);
    developer.log(
      message,
      name: 'SafeKids',
      level: 1200,
      error: error,
      stackTrace: stackTrace,
    );
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  }

  static void analytics(String event, Map<String, dynamic> parameters) {
    info('Analytics: $event', parameters);
    FirebaseCrashlytics.instance.setCustomKey(event, parameters.toString());
  }
}