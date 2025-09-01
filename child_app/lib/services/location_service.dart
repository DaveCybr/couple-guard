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
  DateTime? _lastMovementTime;

  LocationService(this._apiService);

  // Public getter for tracking status
  bool get isTracking => _isTracking;

  // ✅ SIMPLIFIED: Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      // For background location (Android 10+)
      if (permission == LocationPermission.whileInUse) {
        // Request always permission
        permission = await Geolocator.requestPermission();
      }

      print('Location permission status: $permission');
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // ✅ SIMPLIFIED: Start location tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied - cannot start tracking');
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      _isTracking = true;

      // ✅ Start simple periodic updates (every 5 minutes)
      _startPeriodicUpdates();

      // Save tracking state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_tracking_active', true);

      print('Location tracking started successfully');
      return true;
    } catch (e) {
      print('Failed to start location tracking: $e');
      return false;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_tracking_active', false);

    print('Location tracking stopped');
  }

  // ✅ SIMPLIFIED: Start periodic location updates
  void _startPeriodicUpdates() {
    // Start with 5 minute intervals for testing
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      await _getCurrentLocationAndSend(reason: 'periodic');
    });

    // Send initial location immediately
    _getCurrentLocationAndSend(reason: 'initial');
  }

  // ✅ SIMPLIFIED: Get current location and send to server
  Future<void> _getCurrentLocationAndSend({required String reason}) async {
    try {
      print('Getting location for reason: $reason');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increase timeout
      );

      await _sendLocationUpdate(position, reason: reason);
      _lastKnownPosition = position;

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Failed to get current location: $e');

      // Try to use last known position
      if (_lastKnownPosition != null) {
        print('Using last known position');
        await _sendLocationUpdate(_lastKnownPosition!, reason: 'cached');
      } else {
        print('No location available');
      }
    }
  }

  // ✅ SIMPLIFIED: Send location update to server
  Future<void> _sendLocationUpdate(
    Position position, {
    required String reason,
  }) async {
    try {
      // For now, just print the location (remove API call that might be causing issues)
      print(
        'Location update ($reason): ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}m',
      );

      _lastMovementTime = DateTime.now();
      await _saveLastLocation(position, _lastBatteryLevel);

      // TODO: Uncomment when API is ready
      /*
      final response = await _apiService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        batteryLevel: _lastBatteryLevel,
      );

      if (response.success) {
        print('Location sent to server successfully');
      }
      */
    } catch (e) {
      print('Failed to process location update: $e');
    }
  }

  // Save last known location locally
  Future<void> _saveLastLocation(Position position, int batteryLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setDouble('last_accuracy', position.accuracy);
      await prefs.setInt('last_battery_level', batteryLevel);
      await prefs.setString(
        'last_location_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Failed to save last location: $e');
    }
  }

  // Load last known location from storage
  Future<Position?> getLastKnownLocation() async {
    try {
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
    } catch (e) {
      print('Failed to get last known location: $e');
    }

    return null;
  }

  // ✅ SIMPLIFIED: Emergency location update (immediate)
  Future<Position?> getEmergencyLocation() async {
    try {
      print('Getting emergency location...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Failed to get emergency location: $e');
      // Return last known location if can't get current
      return _lastKnownPosition ?? await getLastKnownLocation();
    }
  }

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current location status for UI
  LocationStatus getLocationStatus() {
    if (!_isTracking) return LocationStatus.stopped;
    if (_lastKnownPosition == null) return LocationStatus.searching;

    final timeDiff = DateTime.now().difference(
      _lastMovementTime ?? DateTime.now(),
    );
    if (timeDiff.inMinutes > 10) {
      // 10 minutes threshold
      return LocationStatus.stale;
    }

    return LocationStatus.active;
  }

  // Update battery level (called from battery service)
  void updateBatteryLevel(int batteryLevel) {
    _lastBatteryLevel = batteryLevel;
  }

  // Cleanup
  void dispose() {
    _locationTimer?.cancel();
  }
}

// Location status enum
enum LocationStatus { stopped, searching, active, stale }
