// lib/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  bool _isTracking = false;

  // Battery level tracking
  int _lastBatteryLevel = 100;

  // Movement detection
  double _totalDistance = 0;
  DateTime? _lastMovementTime;

  LocationService(this._apiService);

  // Public getter for tracking status
  bool get isTracking => _isTracking;

  // Check and request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // For Android 10+ background location
    if (permission == LocationPermission.whileInUse) {
      final backgroundPermission = await Permission.locationAlways.request();
      return backgroundPermission.isGranted;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Start location tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    _isTracking = true;

    // Start periodic location updates
    _startPeriodicUpdates();

    // Listen for significant location changes
    _startSignificantLocationMonitoring();

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_tracking_active', true);

    return true;
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_tracking_active', false);
  }

  // Start periodic location updates (every 30 minutes by default)
  void _startPeriodicUpdates() {
    _locationTimer = Timer.periodic(
      Duration(minutes: AppConfig.locationUpdateIntervalMinutes),
      (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }

        await _getCurrentLocationAndSend(reason: 'periodic');
      },
    );

    // Send initial location immediately
    _getCurrentLocationAndSend(reason: 'initial');
  }

  // Monitor significant location changes
  void _startSignificantLocationMonitoring() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConfig.minimumDistanceFilter,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) async {
      if (!_isTracking) return;

      // Check if this is a significant movement
      if (await _isSignificantMovement(position)) {
        await _sendLocationUpdate(position, reason: 'movement');
      }

      _lastKnownPosition = position;
    });
  }

  // Get current location and send to server
  Future<void> _getCurrentLocationAndSend({required String reason}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await _sendLocationUpdate(position, reason: reason);
      _lastKnownPosition = position;
    } catch (e) {
      print('Failed to get location: $e');

      // Try to get last known position
      if (_lastKnownPosition != null) {
        await _sendLocationUpdate(_lastKnownPosition!, reason: 'cached');
      }
    }
  }

  // Check if movement is significant enough to report
  Future<bool> _isSignificantMovement(Position newPosition) async {
    if (_lastKnownPosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // Update if moved more than minimum distance or it's been too long
    final timeDiff = DateTime.now().difference(
      _lastMovementTime ?? DateTime.now(),
    );

    return distance > AppConfig.minimumDistanceFilter ||
        timeDiff.inMinutes > AppConfig.locationUpdateIntervalMinutes;
  }

  // Send location update to server
  Future<void> _sendLocationUpdate(
    Position position, {
    required String reason,
  }) async {
    try {
      final batteryLevel = await _getBatteryLevel();

      final response = await _apiService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        batteryLevel: batteryLevel,
      );

      if (response.success) {
        _lastMovementTime = DateTime.now();
        await _saveLastLocation(position, batteryLevel);

        print(
          'Location updated successfully ($reason): ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      print('Failed to send location update: $e');

      // Add to offline queue
      await _apiService.addToOfflineQueue('/location/update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'battery_level': await _getBatteryLevel(),
      });
    }
  }

  // Get device battery level
  Future<int> _getBatteryLevel() async {
    try {
      // This is a simplified implementation
      // In real app, you'd use battery_plus package
      return _lastBatteryLevel;
    } catch (e) {
      return 100; // Default if can't get battery level
    }
  }

  // Save last known location locally
  Future<void> _saveLastLocation(Position position, int batteryLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
    await prefs.setDouble('last_accuracy', position.accuracy);
    await prefs.setInt('last_battery_level', batteryLevel);
    await prefs.setString(
      'last_location_time',
      DateTime.now().toIso8601String(),
    );
  }

  // Load last known location from storage
  Future<Position?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('last_latitude');
    final lon = prefs.getDouble('last_longitude');
    final accuracy = prefs.getDouble('last_accuracy');

    if (lat != null && lon != null) {
      return Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: accuracy ?? 100,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return null;
  }

  // Adaptive location interval based on movement and battery
  void _adjustLocationInterval() {
    if (!_isTracking) return;

    int intervalMinutes = AppConfig.locationUpdateIntervalMinutes;

    // Reduce frequency if battery is low
    if (_lastBatteryLevel <= AppConfig.lowBatteryThreshold) {
      intervalMinutes *= 2; // 60 minutes when battery low
    }

    if (_lastBatteryLevel <= AppConfig.criticalBatteryThreshold) {
      intervalMinutes *= 4; // 120 minutes when battery critical
    }

    // Restart timer with new interval
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(minutes: intervalMinutes), (
      timer,
    ) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      await _getCurrentLocationAndSend(reason: 'adaptive');
    });
  }

  // Emergency location update (immediate)
  Future<Position?> getEmergencyLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Return last known location if can't get current
      return _lastKnownPosition ?? await getLastKnownLocation();
    }
  }

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get location accuracy status
  LocationAccuracy getCurrentAccuracy() {
    if (_lastKnownPosition == null) return LocationAccuracy.low;

    final accuracy = _lastKnownPosition!.accuracy;
    if (accuracy <= 5) return LocationAccuracy.best;
    if (accuracy <= 20) return LocationAccuracy.high;
    if (accuracy <= 100) return LocationAccuracy.medium;
    return LocationAccuracy.low;
  }

  // Calculate distance traveled today
  Future<double> getTodayDistanceTraveled() async {
    // This would require storing location history locally
    // For now, return accumulated distance
    return _totalDistance;
  }

  // Update battery level (called from battery service)
  void updateBatteryLevel(int batteryLevel) {
    final previousLevel = _lastBatteryLevel;
    _lastBatteryLevel = batteryLevel;

    // Adjust location interval if battery changed significantly
    if ((previousLevel > AppConfig.lowBatteryThreshold &&
            batteryLevel <= AppConfig.lowBatteryThreshold) ||
        (previousLevel > AppConfig.criticalBatteryThreshold &&
            batteryLevel <= AppConfig.criticalBatteryThreshold)) {
      _adjustLocationInterval();
    }
  }

  // Get current location status for UI
  LocationStatus getLocationStatus() {
    if (!_isTracking) return LocationStatus.stopped;
    if (_lastKnownPosition == null) return LocationStatus.searching;

    final timeDiff = DateTime.now().difference(
      _lastMovementTime ?? DateTime.now(),
    );
    if (timeDiff.inMinutes > AppConfig.locationUpdateIntervalMinutes * 2) {
      return LocationStatus.stale;
    }

    return LocationStatus.active;
  }

  // Cleanup
  void dispose() {
    _locationTimer?.cancel();
  }
}

// Location status enum
enum LocationStatus { stopped, searching, active, stale }
