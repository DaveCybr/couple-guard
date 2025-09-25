import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:couple_guard/core/configs/api_config.dart';
import '../models/geofence_model.dart';

class GeofenceService {
  final String authToken;
  final int familyId;
  final String _baseUrl = ApiConfig.baseUrl;

  GeofenceService({required this.authToken, required this.familyId});

  Future<bool> createGeofence({
    required String name,
    required double centerLatitude,
    required double centerLongitude,
    required int radius,
    required String type,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/geofence/create');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      final body = json.encode({
        'family_id': familyId,
        'name': name,
        'center_latitude': centerLatitude,
        'center_longitude': centerLongitude,
        'radius': radius,
        'type': type,
      });

      debugPrint('🌐 Creating geofence with data: $body');
      debugPrint('Bearer $authToken');
      final response = await http.post(url, headers: headers, body: body);

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          debugPrint('✅ Geofence created successfully');
          return true;
        } else {
          debugPrint('❌ API returned success: false');
          return false;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');

        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            debugPrint('Error message: ${errorData['message']}');
          }
        } catch (e) {
          debugPrint('Could not parse error response');
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception in createGeofence: $e');
      return false;
    }
  }

  Future<List<GeofenceModel>?> getGeofences() async {
    try {
      final url = Uri.parse('$_baseUrl/geofence/list?family_id=$familyId');

      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true &&
            responseData['geofences'] != null) {
          final List<dynamic> geofencesJson = responseData['geofences'];

          return geofencesJson
              .map((json) => GeofenceModel.fromJson(json))
              .toList();
        }
      } else {
        debugPrint("⚠️ Failed: ${response.statusCode}, ${response.body}");
      }

      return null;
    } catch (e) {
      debugPrint('❌ Exception in getGeofences: $e');
      return null;
    }
  }

  Future<bool> deleteGeofence(int geofenceId) async {
    try {
      final url = Uri.parse('$_baseUrl/geofence/$geofenceId');

      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Exception in deleteGeofence: $e');
      return false;
    }
  }

  Future<bool> toggleGeofence(int geofenceId, bool isActive) async {
    try {
      final url = Uri.parse('$_baseUrl/geofence/$geofenceId/toggle');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      final body = json.encode({'is_active': isActive});

      final response = await http.patch(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Exception in toggleGeofence: $e');
      return false;
    }
  }
}
