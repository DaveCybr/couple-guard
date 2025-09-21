import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:couple_guard/core/configs/api_config.dart';

class CameraService {
  final String _baseUrl = ApiConfig.baseUrl;

  /// Upload foto
  Future<Map<String, dynamic>> uploadPhoto(
    File file,
    int childId,
    String token,
  ) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$_baseUrl/camera/store"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));
      request.fields["child_id"] = childId.toString();
      request.fields["type"] = "photo";

      request.headers["Authorization"] = "Bearer $token";

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      return {
        "success": response.statusCode == 200,
        "statusCode": response.statusCode,
        "message": respStr,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Upload photo error: $e",
      };
    }
  }

  /// Upload video
  Future<Map<String, dynamic>> uploadVideo(
    File file,
    int childId,
    String token,
  ) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$_baseUrl/camera/store"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));
      request.fields["child_id"] = childId.toString();
      request.fields["type"] = "video";

      request.headers["Authorization"] = "Bearer $token";

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      return {
        "success": response.statusCode == 200,
        "statusCode": response.statusCode,
        "message": respStr,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Upload video error: $e",
      };
    }
  }
}
