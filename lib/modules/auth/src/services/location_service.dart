import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:couple_guard/core/configs/api_config.dart';

typedef OnLocationUpdated = void Function(LatLng newLocation);

class LocationPusherService {
  final String authToken;
  final int familyId;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final String _baseUrl = ApiConfig.baseUrl; // ganti sesuai URL backend

  LocationPusherService({required this.authToken, required this.familyId});

  Future<LatLng?> fetchInitialLocation() async {
    try {
      final url = Uri.parse("$_baseUrl/location/track/$familyId");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['location'] != null) {
          final loc = data['location'];
          return LatLng(
            double.parse(loc['latitude'].toString()),
            double.parse(loc['longitude'].toString()),
          );
        }
      }
    } catch (e) {
      debugPrint("💥 ERROR fetchInitialLocation: $e");
    }
    return null;
  }

  Future<void> initPusher({
    required OnLocationUpdated onLocationUpdated,
  }) async {
    try {
      await _pusher.init(
        apiKey: 'a15743bef505b8594201',
        cluster: 'ap1',
        onConnectionStateChange: (currentState, previousState) {
          debugPrint("🔌 Pusher state: $previousState -> $currentState");
          if (currentState == 'CONNECTED' && previousState == 'CONNECTING') {
            _subscribeToChannel(onLocationUpdated: onLocationUpdated);
          }
        },
        onError: (message, code, error) {
          debugPrint("❌ Pusher Error: $message | code: $code | error: $error");
        },
        onAuthorizer: (channelName, socketId, options) async {
          final authUrl = Uri.parse("$_baseUrl/broadcasting/auth");
          final response = await http.post(
            authUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'socket_id': socketId,
              'channel_name': channelName,
            }),
          );

          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          } else {
            throw Exception('Failed to authorize Pusher channel');
          }
        },
      );

      await _pusher.connect();
    } catch (e) {
      debugPrint("💥 ERROR initializing Pusher: $e");
    }
  }

  Future<void> _subscribeToChannel({
    required OnLocationUpdated onLocationUpdated,
  }) async {
    final channelName = 'private-family.$familyId';
    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName == 'location.updated') {
          try {
            final data = jsonDecode(event.data);
            final lat = double.parse(data['latitude'].toString());
            final lng = double.parse(data['longitude'].toString());
            onLocationUpdated(LatLng(lat, lng));
          } catch (e) {
            debugPrint("⚠️ Failed parse location update: $e");
          }
        }
      },
    );
  }

  void dispose() {
    final channelName = 'private-family.$familyId';
    _pusher.unsubscribe(channelName: channelName);
    _pusher.disconnect();
  }
}
