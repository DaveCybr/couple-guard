// features/location_tracking/data/models/location_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required String id,
    required String childId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String accuracyLevel,
    double? speed,
    double? heading,
    double? altitude,
    required DateTime timestamp,
    required String networkType,
    required int batteryLevel,
    required bool isMoving,
    required bool isRequestedByParent,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) : super(
         id: id,
         childId: childId,
         latitude: latitude,
         longitude: longitude,
         accuracy: accuracy,
         accuracyLevel: accuracyLevel,
         speed: speed,
         heading: heading,
         altitude: altitude,
         timestamp: timestamp,
         networkType: networkType,
         batteryLevel: batteryLevel,
         isMoving: isMoving,
         isRequestedByParent: isRequestedByParent,
         requestId: requestId,
         metadata: metadata,
       );

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      id: entity.id,
      childId: entity.childId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      accuracyLevel: entity.accuracyLevel,
      speed: entity.speed,
      heading: entity.heading,
      altitude: entity.altitude,
      timestamp: entity.timestamp,
      networkType: entity.networkType,
      batteryLevel: entity.batteryLevel,
      isMoving: entity.isMoving,
      isRequestedByParent: entity.isRequestedByParent,
      requestId: entity.requestId,
      metadata: entity.metadata,
    );
  }

  factory LocationModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return LocationModel(
      id: id ?? map['id'] ?? '',
      childId: map['child_id'] ?? '',
      latitude: (map['lat'] ?? map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['lng'] ?? map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy_m'] ?? map['accuracy'] ?? 0.0).toDouble(),
      accuracyLevel: map['accuracy_level'] ?? 'unknown',
      speed: map['speed_mps'] != null ? map['speed_mps'].toDouble() : null,
      heading:
          map['heading_deg'] != null ? map['heading_deg'].toDouble() : null,
      altitude: map['alt_m'] != null ? map['alt_m'].toDouble() : null,
      timestamp: _parseTimestamp(map['timestamp']),
      networkType: map['network'] ?? 'unknown',
      batteryLevel: map['battery_level'] ?? 0,
      isMoving: map['is_moving'] ?? false,
      isRequestedByParent: map['requested_by_parent'] ?? false,
      requestId: map['request_id'],
      metadata: map['metadata'],
    );
  }

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'lat': latitude,
      'lng': longitude,
      'accuracy_m': accuracy,
      'accuracy_level': accuracyLevel,
      'speed_mps': speed,
      'heading_deg': heading,
      'alt_m': altitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'network': networkType,
      'battery_level': batteryLevel,
      'is_moving': isMoving,
      'requested_by_parent': isRequestedByParent,
      'request_id': requestId,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id'); // Firestore generates its own ID
    return map;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }
}
