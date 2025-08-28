// features/location_tracking/domain/repositories/location_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_entity.dart';
import '../entities/tracking_session_entity.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationEntity>> getCurrentLocation({
    bool highAccuracy = true,
    Duration? timeout,
  });

  Future<Either<Failure, void>> uploadLocation(LocationEntity location);

  Future<Either<Failure, List<LocationEntity>>> getCachedLocations();

  Future<Either<Failure, void>> cacheLocation(LocationEntity location);

  Future<Either<Failure, void>> clearCachedLocations();

  Future<Either<Failure, TrackingSessionEntity>> startTrackingSession({
    Duration? interval,
    Map<String, dynamic>? settings,
  });

  Future<Either<Failure, void>> stopTrackingSession(String sessionId);

  Future<Either<Failure, TrackingSessionEntity?>> getCurrentSession();

  Stream<Either<Failure, LocationEntity>> get locationStream;

  Stream<Either<Failure, TrackingSessionEntity>> get sessionStream;
}
