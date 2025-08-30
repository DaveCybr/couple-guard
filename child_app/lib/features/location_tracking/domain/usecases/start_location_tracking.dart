// features/location_tracking/domain/usecases/start_location_tracking.dart

import '../../../location_entity.dart';
import '../entities/tracking_session_entity.dart';

class StartLocationTracking
    implements UseCase<TrackingSessionEntity, StartTrackingParams> {
  final LocationRepository repository;

  StartLocationTracking(this.repository);

  @override
  Future<Either<Failure, TrackingSessionEntity>> call(
    StartTrackingParams params,
  ) async {
    return await repository.startTrackingSession(
      interval: params.interval,
      settings: params.settings,
    );
  }
}

class StartTrackingParams extends Equatable {
  final Duration? interval;
  final Map<String, dynamic>? settings;

  const StartTrackingParams({this.interval, this.settings});

  @override
  List<Object?> get props => [interval, settings];
}
