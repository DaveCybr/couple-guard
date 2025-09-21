import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:couple_guard/core/configs/api_config.dart';

class AlbumCameraService {
  final String _baseUrl = ApiConfig.baseUrl;

  /// Ambil semua foto & video milik child
  Future<Map<String, dynamic>> listCaptures(int childId, String token) async {
    try {
      final url = Uri.parse("$_baseUrl/camera/child/$childId");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message":
              jsonDecode(response.body)["message"] ?? "Gagal mengambil data",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  /// Detail capture (foto/video tertentu)
  Future<Map<String, dynamic>> getCaptureDetail(
    int childId,
    int captureId,
    String token,
  ) async {
    try {
      final url = Uri.parse("$_baseUrl/camera/child/$childId/$captureId");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message":
              jsonDecode(response.body)["message"] ?? "Gagal mengambil detail",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }
}
