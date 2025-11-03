class GeofenceModel {
  final int id;
  final int parentId;
  final String name;
  final double latitude;
  final double longitude;
  final int radius;
  final bool isActive;
  final DateTime createdAt;

  GeofenceModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    required this.createdAt,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] as int,
      parentId: json['parent_id'] as int,
      name: json['name'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: json['radius'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
