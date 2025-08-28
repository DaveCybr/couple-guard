// features/location_tracking/domain/entities/tracking_session_entity.dart
import 'package:child_app/features/location_entity.dart';

class TrackingSessionEntity extends Equatable {
  final String id;
  final String childId;
  final DateTime startTime;
  final DateTime? endTime;
  final TrackingSessionStatus status;
  final Duration interval;
  final int locationCount;
  final double? totalDistance;
  final LocationEntity? lastLocation;

  const TrackingSessionEntity({
    required this.id,
    required this.childId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.interval,
    required this.locationCount,
    this.totalDistance,
    this.lastLocation,
  });

  @override
  List<Object?> get props => [
    id,
    childId,
    startTime,
    endTime,
    status,
    interval,
    locationCount,
    totalDistance,
    lastLocation,
  ];
}

enum TrackingSessionStatus { active, paused, stopped, error }
