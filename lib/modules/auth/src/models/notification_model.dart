class NotificationModel {
  final int id;
  final String deviceId; // Ganti dari childUserId
  final String appName; // Ganti dari appPackage
  final String title;
  final String content;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.deviceId,
    required this.appName,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      appName: json['app_name'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
