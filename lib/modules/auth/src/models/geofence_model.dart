class GeofenceModel {
  final int id;
  final int familyId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final int radius;
  final String type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeofenceModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radius,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'],
      familyId: json['family_id'],
      name: json['name'],
      centerLatitude: double.parse(json['center_latitude'].toString()),
      centerLongitude: double.parse(json['center_longitude'].toString()),
      radius: json['radius'],
      type: json['type'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius': radius,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
