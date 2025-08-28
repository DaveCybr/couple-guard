// features/location_tracking/domain/usecases/get_current_location.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocation implements UseCase<LocationEntity, LocationParams> {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  @override
  Future<Either<Failure, LocationEntity>> call(LocationParams params) async {
    return await repository.getCurrentLocation(
      highAccuracy: params.highAccuracy,
      timeout: params.timeout,
    );
  }
}

class LocationParams extends Equatable {
  final bool highAccuracy;
  final Duration? timeout;

  const LocationParams({this.highAccuracy = true, this.timeout});

  @override
  List<Object?> get props => [highAccuracy, timeout];
}
