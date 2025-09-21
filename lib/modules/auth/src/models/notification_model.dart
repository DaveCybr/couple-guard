class NotificationModel {
  final int id;
  final int childUserId;
  final String? appPackage;
  final String? title;
  final String? content;
  final int? priority;
  final String? category;
  final bool? isFlagged;
  final DateTime timestamp;

  // Relasi child (opsional, karena ada with child di controller)
  final Map<String, dynamic>? child;

  NotificationModel({
    required this.id,
    required this.childUserId,
    this.appPackage,
    this.title,
    this.content,
    this.priority,
    this.category,
    this.isFlagged,
    required this.timestamp,
    this.child,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      childUserId: json['child_user_id'] as int,
      appPackage: json['app_package'],
      title: json['title'],
      content: json['content'],
      priority: json['priority'],
      category: json['category'],
      isFlagged: json['is_flagged'] == true,
      timestamp: DateTime.parse(json['timestamp']),
      child: json['child'],
    );
  }
}
