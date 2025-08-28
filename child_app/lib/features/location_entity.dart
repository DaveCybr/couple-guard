// features/location_tracking/domain/entities/location_entity.dart
import 'package:child_app/main.dart';

class LocationEntity extends Equatable {
  final String id;
  final String childId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String accuracyLevel;
  final double? speed;
  final double? heading;
  final double? altitude;
  final DateTime timestamp;
  final String networkType;
  final int batteryLevel;
  final bool isMoving;
  final bool isRequestedByParent;
  final String? requestId;
  final Map<String, dynamic>? metadata;

  const LocationEntity({
    required this.id,
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.accuracyLevel,
    this.speed,
    this.heading,
    this.altitude,
    required this.timestamp,
    required this.networkType,
    required this.batteryLevel,
    required this.isMoving,
    required this.isRequestedByParent,
    this.requestId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id, childId, latitude, longitude, accuracy, accuracyLevel,
    speed, heading, altitude, timestamp, networkType, batteryLevel,
    isMoving, isRequestedByParent, requestId, metadata,
  ];
}

// features/location_tracking/domain/repositories/location_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_entity.dart';
import '../entities/tracking_session_entity.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationEntity>> getCurrentLocation({
    bool highAccuracy = true,
    Duration? timeout,
  });

  Future<Either<Failure, void>> uploadLocation(LocationEntity location);

  Future<Either<Failure, List<LocationEntity>>> getCachedLocations();

  Future<Either<Failure, void>> cacheLocation(LocationEntity location);

  Future<Either<Failure, void>> clearCachedLocations();

  Future<Either<Failure, TrackingSessionEntity>> startTrackingSession({
    Duration? interval,
    Map<String, dynamic>? settings,
  });

  Future<Either<Failure, void>> stopTrackingSession(String sessionId);

  Future<Either<Failure, TrackingSessionEntity?>> getCurrentSession();

  Stream<Either<Failure, LocationEntity>> get locationStream;

  Stream<Either<Failure, TrackingSessionEntity>> get sessionStream;
}


// features/location_tracking/data/models/location_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required String id,
    required String childId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String accuracyLevel,
    double? speed,
    double? heading,
    double? altitude,
    required DateTime timestamp,
    required String networkType,
    required int batteryLevel,
    required bool isMoving,
    required bool isRequestedByParent,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) : super(
    id: id,
    childId: childId,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    accuracyLevel: accuracyLevel,
    speed: speed,
    heading: heading,
    altitude: altitude,
    timestamp: timestamp,
    networkType: networkType,
    batteryLevel: batteryLevel,
    isMoving: isMoving,
    isRequestedByParent: isRequestedByParent,
    requestId: requestId,
    metadata: metadata,
  );

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      id: entity.id,
      childId: entity.childId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      accuracyLevel: entity.accuracyLevel,
      speed: entity.speed,
      heading: entity.heading,
      altitude: entity.altitude,
      timestamp: entity.timestamp,
      networkType: entity.networkType,
      batteryLevel: entity.batteryLevel,
      isMoving: entity.isMoving,
      isRequestedByParent: entity.isRequestedByParent,
      requestId: entity.requestId,
      metadata: entity.metadata,
    );
  }

  factory LocationModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LocationModel(
      id: id ?? map['id'] ?? '',
      childId: map['child_id'] ?? '',
      latitude: (map['lat'] ?? map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['lng'] ?? map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy_m'] ?? map['accuracy'] ?? 0.0).toDouble(),
      accuracyLevel: map['accuracy_level'] ?? 'unknown',
      speed: map['speed_mps'] != null ? map['speed_mps'].toDouble() : null,
      heading: map['heading_deg'] != null ? map['heading_deg'].toDouble() : null,
      altitude: map['alt_m'] != null ? map['alt_m'].toDouble() : null,
      timestamp: _parseTimestamp(map['timestamp']),
      networkType: map['network'] ?? 'unknown',
      batteryLevel: map['battery_level'] ?? 0,
      isMoving: map['is_moving'] ?? false,
      isRequestedByParent: map['requested_by_parent'] ?? false,
      requestId: map['request_id'],
      metadata: map['metadata'],
    );
  }

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'lat': latitude,
      'lng': longitude,
      'accuracy_m': accuracy,
      'accuracy_level': accuracyLevel,
      'speed_mps': speed,
      'heading_deg': heading,
      'alt_m': altitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'network': networkType,
      'battery_level': batteryLevel,
      'is_moving': isMoving,
      'requested_by_parent': isRequestedByParent,
      'request_id': requestId,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id'); // Firestore generates its own ID
    return map;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }
}

// features/location_tracking/data/datasources/location_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<void> uploadLocation(LocationModel location);
  Future<List<LocationModel>> getLocationHistory(String childId, {int limit = 100});
  Future<LocationModel?> getLatestLocation(String childId);
  Stream<LocationModel> watchLatestLocation(String childId);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final FirebaseFirestore firestore;

  LocationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> uploadLocation(LocationModel location) async {
    try {
      final batch = firestore.batch();

      // Save to history collection
      final historyRef = firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(location.childId)
          .collection(AppConstants.kLocationsCollection);
      
      batch.set(historyRef.doc(), location.toFirestore());

      // Update latest location
      final latestRef = firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(location.childId)
          .collection('latest')
          .doc(AppConstants.kLatestPosition);
      
      batch.set(latestRef, location.toFirestore(), SetOptions(merge: true));

      // If requested by parent, save to parent requests
      if (location.isRequestedByParent && location.requestId != null) {
        final requestRef = firestore
            .collection(AppConstants.kChildrenCollection)
            .doc(location.childId)
            .collection('parent_requests')
            .doc(location.requestId!);
        
        batch.set(requestRef, location.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
      AppLogger.info('Location uploaded successfully: ${location.id}');
    } catch (e) {
      AppLogger.error('Failed to upload location', e);
      throw ServerException(message: 'Failed to upload location: $e');
    }
  }

  @override
  Future<List<LocationModel>> getLocationHistory(String childId, {int limit = 100}) async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(childId)
          .collection(AppConstants.kLocationsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get location history', e);
      throw ServerException(message: 'Failed to get location history: $e');
    }
  }

  @override
  Future<LocationModel?> getLatestLocation(String childId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.kChildrenCollection)
          .doc(childId)
          .collection('latest')
          .doc(AppConstants.kLatestPosition)
          .get();

      if (doc.exists) {
        return LocationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get latest location', e);
      throw ServerException(message: 'Failed to get latest location: $e');
    }
  }

  @override
  Stream<LocationModel> watchLatestLocation(String childId) {
    return firestore
        .collection(AppConstants.kChildrenCollection)
        .doc(childId)
        .collection('latest')
        .doc(AppConstants.kLatestPosition)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => LocationModel.fromFirestore(doc));
  }
}

// features/location_tracking/data/datasources/location_local_datasource.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/utils/logger.dart';
import '../models/location_model.dart';

abstract class LocationLocalDataSource {
  Future<void> cacheLocation(LocationModel location);
  Future<List<LocationModel>> getCachedLocations();
  Future<void> clearCachedLocations();
  Future<LocationModel?> getLastCachedLocation();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  final LocalDatabase database;

  LocationLocalDataSourceImpl({required this.database});

  @override
  Future<void> cacheLocation(LocationModel location) async {
    try {
      final db = await database.database;
      await db.insert(
        'cached_locations',
        {
          'id': location.id,
          'data': json.encode(location.toMap()),
          'timestamp': location.timestamp.millisecondsSinceEpoch,
          'uploaded': 0, // 0 = not uploaded, 1 = uploaded
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.debug('Location cached locally: ${location.id}');
    } catch (e) {
      AppLogger.error('Failed to cache location', e);
      throw CacheException(message: 'Failed to cache location: $e');
    }
  }

  @override
  Future<List<LocationModel>> getCachedLocations() async {
    try {
      final db = await database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cached_locations',
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) {
        final data = json.decode(map['data']) as Map<String, dynamic>;
        return LocationModel.fromMap(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get cached locations', e);
      throw CacheException(message: 'Failed to get cached locations: $e');
    }
  }

  @override
  Future<void> clearCachedLocations() async {
    try {
      final db = await database.database;
      await db.delete('cached_locations');
      AppLogger.debug('Cached locations cleared');
    } catch (e) {
      AppLogger.error('Failed to clear cached locations', e);
      throw CacheException(message: 'Failed to clear cached locations: $e');
    }
  }

  @override
  Future<LocationModel?> getLastCachedLocation() async {
    try {
      final db = await database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cached_locations',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final data = json.decode(maps.first['data']) as Map<String, dynamic>;
        return LocationModel.fromMap(data);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get last cached location', e);
      throw CacheException(message: 'Failed to get last cached location: $e');
    }
  }
}

// features/location_tracking/data/repositories/location_repository_impl.dart
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/platform/device_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/tracking_session_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_datasource.dart';
import '../datasources/location_remote_datasource.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final LocationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final DeviceInfo deviceInfo;

  TrackingSessionEntity? _currentSession;
  Timer? _trackingTimer;
  final StreamController<Either<Failure, LocationEntity>> _locationController = 
      StreamController.broadcast();
  final StreamController<Either<Failure, TrackingSessionEntity>> _sessionController = 
      StreamController.broadcast();

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.deviceInfo,
  });

  @override
  Stream<Either<Failure, LocationEntity>> get locationStream => 
      _locationController.stream;

  @override
  Stream<Either<Failure, TrackingSessionEntity>> get sessionStream => 
      _sessionController.stream;

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation({
    bool highAccuracy = true,
    Duration? timeout,
  }) async {
    try {
      // Check permissions first
      final permissionResult = await _checkLocationPermission();
      if (permissionResult != null) {
        return Left(permissionResult);
      }

      Position? position;
      String accuracyLevel = 'unknown';

      // Strategy 1: High accuracy
      if (highAccuracy) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: timeout ?? const Duration(seconds: 15),
          );
          accuracyLevel = 'high';
        } catch (e) {
          AppLogger.warning('High accuracy location failed', e);
        }
      }

      // Strategy 2: Medium accuracy fallback
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: timeout ?? const Duration(seconds: 30),
          );
          accuracyLevel = 'medium';
        } catch (e) {
          AppLogger.warning('Medium accuracy location failed', e);
        }
      }

      // Strategy 3: Low accuracy fallback
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: timeout ?? const Duration(seconds: 60),
          );
          accuracyLevel = 'low';
        } catch (e) {
          AppLogger.warning('Low accuracy location failed', e);
        }
      }

      // Strategy 4: Last known position
      if (position == null) {
        position = await Geolocator.getLastKnownPosition();
        accuracyLevel = 'cached';
      }

      if (position == null) {
        return const Left(LocationFailure(
          message: 'Unable to get current location',
          code: 'LOCATION_UNAVAILABLE',
        ));
      }

      // Create location entity
      final deviceDetails = await deviceInfo.getDeviceDetails();
      final networkType = await networkInfo.connectionType;
      
      final location = LocationModel(
        id: const Uuid().v4(),
        childId: deviceDetails['child_id'] ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        accuracyLevel: accuracyLevel,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        timestamp: DateTime.now(),
        networkType: networkType,
        batteryLevel: deviceDetails['battery_level'] ?? 0,
        isMoving: (position.speed ?? 0) > 0.5,
        isRequestedByParent: false,
      );

      // Cache location locally
      await localDataSource.cacheLocation(location);

      // Emit to stream
      _locationController.add(Right(location));

      return Right(location);
    } catch (e) {
      AppLogger.error('Failed to get current location', e);
      return Left(LocationFailure(
        message: 'Failed to get current location: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> uploadLocation(LocationEntity location) async {
    try {
      final locationModel = LocationModel.fromEntity(location);
      
      if (await networkInfo.isConnected) {
        // Upload to remote
        await remoteDataSource.uploadLocation(locationModel);
      } else {
        // Cache for later upload
        await localDataSource.cacheLocation(locationModel);
      }

      return const Right(null);
    } catch (e) {
      AppLogger.error('Failed to upload location', e);
      if (e is ServerException) {
        return Left(NetworkFailure(message: e.message, originalError: e));
      }
      return Left(LocationFailure(
        message: 'Failed to upload location: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, TrackingSessionEntity>> startTrackingSession({
    Duration? interval,
    Map<String, dynamic>? settings,
  }) async {
    try {
      // Stop existing session if any
      if (_currentSession != null) {
        await stopTrackingSession(_currentSession!.id);
      }

      final sessionId = const Uuid().v4();
      final deviceDetails = await deviceInfo.getDeviceDetails();
      
      _currentSession = TrackingSessionEntity(
        id: sessionId,
        childId: deviceDetails['child_id'] ?? '',
        startTime: DateTime.now(),
        status: TrackingSessionStatus.active,
        interval: interval ?? const Duration(minutes: 10),
        locationCount: 0,
      );

      // Start periodic location tracking
      _startPeriodicTracking(_currentSession!.interval);

      // Emit session update
      _sessionController.add(Right(_currentSession!));

      AppLogger.info('Tracking session started: $sessionId');
      return Right(_currentSession!);
    } catch (e) {
      AppLogger.error('Failed to start tracking session', e);
      return Left(LocationFailure(
        message: 'Failed to start tracking session: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> stopTrackingSession(String sessionId) async {
    try {
      if (_currentSession?.id == sessionId) {
        _trackingTimer?.cancel();
        _trackingTimer = null;

        _currentSession = _currentSession!.copyWith(
          endTime: DateTime.now(),
          status: TrackingSessionStatus.stopped,
        );

        // Emit session update
        _sessionController.add(Right(_currentSession!));

        AppLogger.info('Tracking session stopped: $sessionId');
      }

      return const Right(null);
    } catch (e) {
      AppLogger.error('Failed to stop tracking session', e);
      return Left(LocationFailure(
        message: 'Failed to stop tracking session: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, TrackingSessionEntity?>> getCurrentSession() async {
    return Right(_currentSession);
  }

  @override
  Future<Either<Failure, List<LocationEntity>>> getCachedLocations() async {
    try {
      final locations = await localDataSource.getCachedLocations();
      return Right(locations);
    } catch (e) {
      AppLogger.error('Failed to get cached locations', e);
      if (e is CacheException) {
        return Left(CacheFailure(message: e.message, originalError: e));
      }
      return Left(LocationFailure(
        message: 'Failed to get cached locations: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> cacheLocation(LocationEntity location) async {
    try {
      final locationModel = LocationModel.fromEntity(location);
      await localDataSource.cacheLocation(locationModel);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Failed to cache location', e);
      if (e is CacheException) {
        return Left(CacheFailure(message: e.message, originalError: e));
      }
      return Left(LocationFailure(
        message: 'Failed to cache location: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> clearCachedLocations() async {
    try {
      await localDataSource.clearCachedLocations();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Failed to clear cached locations', e);
      if (e is CacheException) {
        return Left(CacheFailure(message: e.message, originalError: e));
      }
      return Left(LocationFailure(
        message: 'Failed to clear cached locations: $e',
        originalError: e,
      ));
    }
  }

  void _startPeriodicTracking(Duration interval) {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(interval, (_) async {
      final result = await getCurrentLocation();
      result.fold(
        (failure) => AppLogger.error('Periodic location failed: ${failure.message}'),
        (location) async {
          await uploadLocation(location);
          // Update session
          if (_currentSession != null) {
            _currentSession = _currentSession!.copyWith(
              locationCount: _currentSession!.locationCount + 1,
              lastLocation: location,
            );
            _sessionController.add(Right(_currentSession!));
          }
        },
      );
    });
  }

  Future<Failure?> _checkLocationPermission() async {
    // Check if location service is enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationFailure(
        message: 'Location services are disabled',
        code: 'LOCATION_SERVICE_DISABLED',
      );
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const PermissionFailure(
          message: 'Location permissions are denied',
          code: 'LOCATION_PERMISSION_DENIED',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const PermissionFailure(
        message: 'Location permissions are permanently denied',
        code: 'LOCATION_PERMISSION_DENIED_FOREVER',
      );
    }

    return null;
  }

  void dispose() {
    _trackingTimer?.cancel();
    _locationController.close();
    _sessionController.close();
  }
}