// services/location_service.dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/core/configs/api_config.dart';

class LocationPusherService {
  final String authToken;
  final String familyId;
  late PusherChannelsFlutter pusher;
  bool _isConnected = false;
  Function(LatLng)? onLocationUpdated;
  final String _baseUrl = ApiConfig.baseUrl;

  LocationPusherService({required this.authToken, required this.familyId});

  // Model untuk response lokasi dari API

  // Fetch lokasi awal dari API
  Future<LatLng?> fetchInitialLocation() async {
    try {
      print("📍 Fetching initial location for family: $familyId");

      // Ganti dengan endpoint API Anda untuk mendapatkan lokasi terbaru
      final response = await http.get(
        Uri.parse('$_baseUrl/locations/$familyId/latest'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = LocationResponse.fromJson(data['data']);
        print(
          "✅ Initial location: ${location.latitude}, ${location.longitude}",
        );
        return location.toLatLng();
      } else {
        print("❌ Failed to fetch initial location: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching initial location: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> requestLocationUpdate() async {
    try {
      final url = Uri.parse('$_baseUrl/commands/request-location');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'device_id': familyId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Permintaan lokasi berhasil dikirim',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal mengirim permintaan lokasi',
          'error': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'error': e.toString()};
    }
  }

  // Inisialisasi Pusher
  Future<void> initPusher({required Function(LatLng) onLocationUpdated}) async {
    try {
      this.onLocationUpdated = onLocationUpdated;

      pusher = PusherChannelsFlutter.getInstance();

      await pusher.init(
        apiKey: 'a15743bef505b8594201', // Ganti dengan API key Pusher Anda
        cluster: 'ap1', // Ganti dengan cluster Pusher Anda
        onConnectionStateChange: onConnectionStateChange,
        // onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
      );

      await pusher.connect();

      // Subscribe ke channel umum untuk semua device dalam family
      await pusher.subscribe(channelName: 'location-updates');
      print("✅ Subscribed to location-updates channel");
    } catch (e) {
      print("❌ Error initializing Pusher: $e");
      throw Exception('Failed to initialize Pusher: $e');
    }
  }

  // Event handlers untuk Pusher
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("🔌 Pusher Connection: $previousState -> $currentState");
    _isConnected = currentState == 'connected';
  }

  void onError(dynamic error) {
    print("❌ Pusher Error: $error");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("✅ Subscribed to channel: $channelName");
  }

  void onSubscriptionError(String channelName, dynamic error) {
    print("❌ Subscription error to $channelName: $error");
  }

  void onEvent(PusherEvent event) {
    print("📡 Pusher Event: ${event.eventName} on ${event.channelName}");

    if (event.eventName == 'location.updated') {
      try {
        final data = json.decode(event.data!);

        // Validasi data yang diterima
        if (data['latitude'] != null && data['longitude'] != null) {
          final newLocation = LatLng(
            double.parse(data['latitude'].toString()),
            double.parse(data['longitude'].toString()),
          );

          print(
            "📍 Location update received: ${newLocation.latitude}, ${newLocation.longitude}",
          );

          // Panggil callback dengan lokasi baru
          onLocationUpdated?.call(newLocation);

          // Log violations jika ada
          if (data['violations'] != null &&
              (data['violations'] as List).isNotEmpty) {
            print("🚨 Geofence violations detected: ${data['violations']}");
          }
        } else {
          print("⚠️ Invalid location data received: $data");
        }
      } catch (e) {
        print("❌ Error parsing location data: $e");
      }
    }
  }

  // Subscribe ke device tertentu
  Future<void> subscribeToDevice(String deviceId) async {
    try {
      await pusher.subscribe(channelName: 'device.$deviceId');
      print("✅ Subscribed to device channel: device.$deviceId");
    } catch (e) {
      print("❌ Error subscribing to device channel: $e");
    }
  }

  // Unsubscribe dari device
  Future<void> unsubscribeFromDevice(String deviceId) async {
    try {
      await pusher.unsubscribe(channelName: 'device.$deviceId');
      print("✅ Unsubscribed from device channel: device.$deviceId");
    } catch (e) {
      print("❌ Error unsubscribing from device channel: $e");
    }
  }

  // Dispose resources
  void dispose() {
    try {
      pusher.disconnect();
      print("🔌 Pusher disconnected");
    } catch (e) {
      print("❌ Error disposing Pusher: $e");
    }
  }

  // Get connection status
  bool get isConnected => _isConnected;
}

class LocationResponse {
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationResponse({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timestamp: json['timestamp'] ?? '',
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
