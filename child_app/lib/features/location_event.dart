// features/location_tracking/presentation/bloc/location_event.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class StartLocationTracking extends LocationEvent {
  final Duration? interval;
  final Map<String, dynamic>? settings;

  const StartLocationTracking({this.interval, this.settings});

  @override
  List<Object?> get props => [interval, settings];
}

class StopLocationTracking extends LocationEvent {
  final String sessionId;

  const StopLocationTracking(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class GetCurrentLocation extends LocationEvent {
  final bool highAccuracy;
  final Duration? timeout;
  final bool requestedByParent;
  final String? requestId;

  const GetCurrentLocation({
    this.highAccuracy = true,
    this.timeout,
    this.requestedByParent = false,
    this.requestId,
  });

  @override
  List<Object?> get props => [highAccuracy, timeout, requestedByParent, requestId];
}

class UploadLocation extends LocationEvent {
  final LocationEntity location;

  const UploadLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationUpdated extends LocationEvent {
  final LocationEntity location;

  const LocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class TrackingSessionUpdated extends LocationEvent {
  final TrackingSessionEntity session;

  const TrackingSessionUpdated(this.session);

  @override
  List<Object?> get props => [session];
}

class SyncCachedLocations extends LocationEvent {
  const SyncCachedLocations();
}

class ClearLocationCache extends LocationEvent {
  const ClearLocationCache();
}

// features/location_tracking/presentation/bloc/location_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/tracking_session_entity.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  final String message;

  const LocationLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

class LocationLoaded extends LocationState {
  final LocationEntity? currentLocation;
  final TrackingSessionEntity? currentSession;
  final List<LocationEntity> recentLocations;
  final int cachedLocationsCount;
  final bool isTracking;
  final String status;

  const LocationLoaded({
    this.currentLocation,
    this.currentSession,
    this.recentLocations = const [],
    this.cachedLocationsCount = 0,
    this.isTracking = false,
    this.status = 'Ready',
  });

  LocationLoaded copyWith({
    LocationEntity? currentLocation,
    TrackingSessionEntity? currentSession,
    List<LocationEntity>? recentLocations,
    int? cachedLocationsCount,
    bool? isTracking,
    String? status,
  }) {
    return LocationLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      currentSession: currentSession ?? this.currentSession,
      recentLocations: recentLocations ?? this.recentLocations,
      cachedLocationsCount: cachedLocationsCount ?? this.cachedLocationsCount,
      isTracking: isTracking ?? this.isTracking,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    currentLocation,
    currentSession,
    recentLocations,
    cachedLocationsCount,
    isTracking,
    status,
  ];
}

class LocationError extends LocationState {
  final String message;
  final String code;
  final dynamic error;

  const LocationError({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.error,
  });

  @override
  List<Object?> get props => [message, code, error];
}

// features/location_tracking/presentation/bloc/location_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/start_location_tracking.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/upload_location.dart';
import '../../domain/usecases/stop_location_tracking.dart';
import '../../domain/repositories/location_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final StartLocationTracking startTracking;
  final StopLocationTracking stopTracking;
  final GetCurrentLocation getCurrentLocation;
  final UploadLocation uploadLocation;
  final LocationRepository repository;

  StreamSubscription? _locationSubscription;
  StreamSubscription? _sessionSubscription;

  LocationBloc({
    required this.startTracking,
    required this.stopTracking,
    required this.getCurrentLocation,
    required this.uploadLocation,
    required this.repository,
  }) : super(const LocationInitial()) {
    
    // Register event handlers
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<UploadLocation>(_onUploadLocation);
    on<LocationUpdated>(_onLocationUpdated);
    on<TrackingSessionUpdated>(_onTrackingSessionUpdated);
    on<SyncCachedLocations>(_onSyncCachedLocations);
    on<ClearLocationCache>(_onClearLocationCache);

    // Listen to location stream
    _locationSubscription = repository.locationStream.listen(
      (result) {
        result.fold(
          (failure) {
            AppLogger.error('Location stream error: ${failure.message}');
            add(LocationError(
              message: failure.message,
              code: failure.code,
              error: failure.originalError,
            ) as LocationEvent);
          },
          (location) => add(LocationUpdated(location)),
        );
      },
    );

    // Listen to session stream
    _sessionSubscription = repository.sessionStream.listen(
      (result) {
        result.fold(
          (failure) {
            AppLogger.error('Session stream error: ${failure.message}');
          },
          (session) => add(TrackingSessionUpdated(session)),
        );
      },
    );
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(const LocationLoading(message: 'Starting location tracking...'));

      final result = await startTracking(StartTrackingParams(
        interval: event.interval,
        settings: event.settings,
      ));

      result.fold(
        (failure) {
          AppLogger.error('Failed to start tracking: ${failure.message}');
          emit(LocationError(
            message: failure.message,
            code: failure.code,
            error: failure.originalError,
          ));
        },
        (session) {
          AppLogger.info('Location tracking started: ${session.id}');
          if (state is LocationLoaded) {
            emit((state as LocationLoaded).copyWith(
              currentSession: session,
              isTracking: true,
              status: 'Tracking active',
            ));
          } else {
            emit(LocationLoaded(
              currentSession: session,
              isTracking: true,
              status: 'Tracking active',
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error starting tracking', e);
      emit(LocationError(
        message: 'Unexpected error starting tracking: $e',
        error: e,
      ));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(const LocationLoading(message: 'Stopping location tracking...'));

      final result = await stopTracking(StopTrackingParams(event.sessionId));

      result.fold(
        (failure) {
          AppLogger.error('Failed to stop tracking: ${failure.message}');
          emit(LocationError(
            message: failure.message,
            code: failure.code,
            error: failure.originalError,
          ));
        },
        (_) {
          AppLogger.info('Location tracking stopped');
          if (state is LocationLoaded) {
            emit((state as LocationLoaded).copyWith(
              isTracking: false,
              status: 'Tracking stopped',
            ));
          } else {
            emit(const LocationLoaded(
              isTracking: false,
              status: 'Tracking stopped',
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error stopping tracking', e);
      emit(LocationError(
        message: 'Unexpected error stopping tracking: $e',
        error: e,
      ));
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      if (state is! LocationLoaded) {
        emit(const LocationLoading(message: 'Getting current location...'));
      }

      final result = await getCurrentLocation(LocationParams(
        highAccuracy: event.highAccuracy,
        timeout: event.timeout,
      ));

      result.fold(
        (failure) {
          AppLogger.error('Failed to get location: ${failure.message}');
          emit(LocationError(
            message: failure.message,
            code: failure.code,
            error: failure.originalError,
          ));
        },
        (location) {
          AppLogger.info('Current location obtained: ${location.latitude}, ${location.longitude}');
          
          // If requested by parent, upload immediately
          if (event.requestedByParent) {
            add(UploadLocation(location.copyWith(
              isRequestedByParent: true,
              requestId: event.requestId,
            )));
          }

          if (state is LocationLoaded) {
            emit((state as LocationLoaded).copyWith(
              currentLocation: location,
              status: event.requestedByParent 
                ? 'Location sent to parent'
                : 'Location updated',
            ));
          } else {
            emit(LocationLoaded(
              currentLocation: location,
              status: event.requestedByParent 
                ? 'Location sent to parent'
                : 'Location updated',
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error getting location', e);
      emit(LocationError(
        message: 'Unexpected error getting location: $e',
        error: e,
      ));
    }
  }

  Future<void> _onUploadLocation(
    UploadLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final result = await uploadLocation(UploadLocationParams(event.location));

      result.fold(
        (failure) {
          AppLogger.error('Failed to upload location: ${failure.message}');
          // Don't emit error for upload failures, just log them
        },
        (_) {
          AppLogger.info('Location uploaded successfully');
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error uploading location', e);
    }
  }

  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      final updatedRecentLocations = [
        event.location,
        ...currentState.recentLocations.take(9),
      ].toList();

      emit(currentState.copyWith(
        currentLocation: event.location,
        recentLocations: updatedRecentLocations,
        status: 'Location updated',
      ));
    } else {
      emit(LocationLoaded(
        currentLocation: event.location,
        recentLocations: [event.location],
        status: 'Location updated',
      ));
    }
  }

  void _onTrackingSessionUpdated(
    TrackingSessionUpdated event,
    Emitter<LocationState> emit,
  ) {
    if (state is LocationLoaded) {
      emit((state as LocationLoaded).copyWith(
        currentSession: event.session,
        isTracking: event.session.status == TrackingSessionStatus.active,
        status: 'Session updated',
      ));
    } else {
      emit(LocationLoaded(
        currentSession: event.session,
        isTracking: event.session.status == TrackingSessionStatus.active,
        status: 'Session updated',
      ));
    }
  }

  Future<void> _onSyncCachedLocations(
    SyncCachedLocations event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final cachedResult = await repository.getCachedLocations();
      cachedResult.fold(
        (failure) {
          AppLogger.error('Failed to get cached locations: ${failure.message}');
        },
        (cachedLocations) async {
          AppLogger.info('Syncing ${cachedLocations.length} cached locations');
          
          for (final location in cachedLocations) {
            final uploadResult = await repository.uploadLocation(location);
            uploadResult.fold(
              (failure) => AppLogger.error('Failed to sync location: ${failure.message}'),
              (_) => AppLogger.debug('Location synced: ${location.id}'),
            );
          }

          // Clear cache after successful sync
          await repository.clearCachedLocations();
          
          if (state is LocationLoaded) {
            emit((state as LocationLoaded).copyWith(
              cachedLocationsCount: 0,
              status: 'Locations synced',
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error syncing locations', e);
    }
  }

  Future<void> _onClearLocationCache(
    ClearLocationCache event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final result = await repository.clearCachedLocations();
      result.fold(
        (failure) {
          AppLogger.error('Failed to clear cache: ${failure.message}');
          emit(LocationError(
            message: failure.message,
            code: failure.code,
            error: failure.originalError,
          ));
        },
        (_) {
          AppLogger.info('Location cache cleared');
          if (state is LocationLoaded) {
            emit((state as LocationLoaded).copyWith(
              cachedLocationsCount: 0,
              status: 'Cache cleared',
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error clearing cache', e);
      emit(LocationError(
        message: 'Unexpected error clearing cache: $e',
        error: e,
      ));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _sessionSubscription?.cancel();
    return super.close();
  }
}

// features/location_tracking/presentation/pages/location_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/location_status_widget.dart';
import '../widgets/location_info_widget.dart';
import '../widgets/tracking_controls_widget.dart';
import '../widgets/location_history_widget.dart';

class LocationDashboardPage extends StatelessWidget {
  const LocationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<LocationBloc>().add(
                        const GetCurrentLocation(),
                      );
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, state),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(context, state),
                      const SizedBox(height: 24),
                      LocationStatusWidget(),
                      const SizedBox(height: 16),
                      if (state is LocationLoaded && state.currentLocation != null)
                        LocationInfoWidget(location: state.currentLocation!),
                      const SizedBox(height: 16),
                      TrackingControlsWidget(),
                      const SizedBox(height: 16),
                      if (state is LocationLoaded && state.recentLocations.isNotEmpty)
                        LocationHistoryWidget(locations: state.recentLocations),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, state),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, LocationState state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'SafeKids Tracker',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (state is LocationLoaded && state.cachedLocationsCount > 0)
          IconButton(
            icon: Badge(
              label: Text('${state.cachedLocationsCount}'),
              child: const Icon(Icons.sync, color: Colors.white),
            ),
            onPressed: () {
              context.read<LocationBloc>().add(const SyncCachedLocations());
            },
          ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, LocationState state) {
    String statusText = 'Ready';
    Color statusColor = AppColors.success;
    IconData statusIcon = Icons.check_circle;

    if (state is LocationLoading) {
      statusText = state.message;
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_empty;
    } else if (state is LocationError) {
      statusText = 'Error: ${state.message}';
      statusColor = AppColors.error;
      statusIcon = Icons.error;
    } else if (state is LocationLoaded) {
      statusText = state.status;
      if (state.isTracking) {
        statusColor = AppColors.success;
        statusIcon = Icons.gps_fixed;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Status',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: AppTextStyles.h4.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.my_location,
              title: 'Get Location',
              subtitle: 'Send current location',
              onTap: () {
                context.read<LocationBloc>().add(
                  const GetCurrentLocation(requestedByParent: true),
                );
              },
            ),
            _buildActionCard(
              context: context,
              icon: Icons.sync,
              title: 'Sync Data',
              subtitle: 'Upload cached data',
              onTap: () {
                context.read<LocationBloc>().add(
                  const SyncCachedLocations(),
                );
              },
            ),
            _buildActionCard(
              context: context,
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              subtitle: 'Remove local data',
              onTap: () {
                _showClearCacheDialog(context);
              },
            ),
            _buildActionCard(
              context: context,
              icon: Icons.emergency,
              title: 'Emergency',
              subtitle: 'Send SOS signal',
              onTap: () {
                _showEmergencyDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached location data from your device. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LocationBloc>().add(const ClearLocationCache());
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'This will send an emergency signal to your parents with your '
          'current location. Use only in real emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement emergency functionality
              context.read<LocationBloc>().add(
                const GetCurrentLocation(
                  requestedByParent: true,
                  highAccuracy: true,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }
}

// features/location_tracking/presentation/widgets/location_status_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_state.dart';

class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusIndicator(context, state),
                const SizedBox(height: 16),
                _buildStatusDetails(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, LocationState state) {
    bool isActive = false;
    Color statusColor = AppColors.grey;
    String statusText = 'Unknown';

    if (state is LocationLoaded) {
      isActive = state.isTracking;
      statusColor = isActive ? AppColors.success : AppColors.warning;
      statusText = isActive ? 'Active' : 'Inactive';
    } else if (state is LocationLoading) {
      statusColor = AppColors.warning;
      statusText = 'Loading';
    } else if (state is LocationError) {
      statusColor = AppColors.error;
      statusText = 'Error';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withOpacity(0.1),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isActive ? Icons.gps_fixed : Icons.gps_off,
                size: 32,
                color: statusColor,
              ),
              if (isActive)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Tracking',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: AppTextStyles.bodyLarge.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDetails(BuildContext context, LocationState state) {
    if (state is! LocationLoaded) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem(
              icon: Icons.schedule,
              label: 'Interval',
              value: state.currentSession?.interval.inMinutes.toString() ?? '--',
              unit: 'min',
            ),
            _buildStatusItem(
              icon: Icons.location_on,
              label: 'Locations',
              value: state.currentSession?.locationCount.toString() ?? '0',
              unit: 'sent',
            ),
            _buildStatusItem(
              icon: Icons.storage,
              label: 'Cached',
              value: state.cachedLocationsCount.toString(),
              unit: 'items',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}