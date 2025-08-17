// lib/core/utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHandler {
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return true;
      default:
        return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    return {
      'location': await requestLocationPermission(),
      'camera': await requestCameraPermission(),
      'microphone': await requestMicrophonePermission(),
      'notification': await requestNotificationPermission(),
      'storage': await requestStoragePermission(),
    };
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
