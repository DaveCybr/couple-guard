import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:couple_guard/core/configs/api_config.dart';
import '../models/geofence_model.dart';

class GeofenceService {
  final String authToken;
  final String _baseUrl = ApiConfig.baseUrl;

  GeofenceService({required this.authToken}); // Hapus familyId dari constructor

  Future<bool> createGeofence({
    required String name,
    required double latitude, // Ganti dari centerLatitude
    required double longitude, // Ganti dari centerLongitude
    required int radius,
    // Hapus parameter type
  }) async {
    try {
      // Sesuaikan endpoint dengan backend
      final url = Uri.parse('$_baseUrl/geofences');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      // Sesuaikan body dengan backend
      final body = json.encode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        // Hapus family_id dan type
      });

      debugPrint('🌐 Creating geofence with data: $body');
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
      final url = Uri.parse('$_baseUrl/geofences');
      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      debugPrint('📡 Meminta data geofence dari: $url');

      final response = await http.get(url, headers: headers);
      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('📦 Response Body: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];

          List<GeofenceModel> geofences = [];

          if (data is List) {
            geofences = data
                .map(
                  (e) => GeofenceModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
          } else if (data is Map) {
            geofences = [
              GeofenceModel.fromJson(Map<String, dynamic>.from(data)),
            ];
          }

          debugPrint('🎯 Berhasil memuat ${geofences.length} geofence(s)');
          return geofences;
        } else {
          debugPrint('⚠️ Response success=false atau data kosong.');
        }
      } else {
        debugPrint('❌ Gagal memuat geofence.');
        debugPrint('   ↳ Status Code: ${response.statusCode}');
        debugPrint('   ↳ Body: ${response.body}');
      }

      return null;
    } catch (e, stack) {
      debugPrint('🚨 Exception dalam getGeofences: $e');
      debugPrint('📄 Stack trace: $stack');
      return null;
    }
  }

  Future<bool> deleteGeofence(int geofenceId) async {
    try {
      // Sesuaikan endpoint dengan backend (jika ada)
      final url = Uri.parse('$_baseUrl/geofences/$geofenceId');

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

  Future<bool> updateGeofence({
    required int geofenceId,
    required String name,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/geofences/$geofenceId');
      final headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'name': name,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius,
      });

      debugPrint('📝 Update geofence ID $geofenceId: $body');

      final response = await http.put(url, headers: headers, body: body);
      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('🚨 Error update geofence: $e');
      return false;
    }
  }
}
