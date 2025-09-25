import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/geofence_service.dart';
import '../models/geofence_model.dart'; // Import your GeofenceModel
import './loading_screen.dart';
import '../../../../core/constants/app_colors.dart';

class RealtimeMapWidget extends StatefulWidget {
  final int familyId;
  final String authToken;

  const RealtimeMapWidget({
    Key? key,
    required this.familyId,
    required this.authToken,
  }) : super(key: key);

  @override
  State<RealtimeMapWidget> createState() => _RealtimeMapWidgetState();
}

class _RealtimeMapWidgetState extends State<RealtimeMapWidget> {
  final MapController _mapController = MapController();
  late LocationPusherService _locationService;
  late GeofenceService _geofenceService;
  LatLng _childLocation = const LatLng(-6.200000, 106.816666);
  List<GeofenceModel> _geofences = [];
  bool _isMapReady = false;
  bool _isLocationLoaded = false;
  bool _areGeofencesLoaded = false;

  @override
  void initState() {
    super.initState();

    _locationService = LocationPusherService(
      authToken: widget.authToken,
      familyId: widget.familyId,
    );

    _geofenceService = GeofenceService(
      authToken: widget.authToken,
      familyId: widget.familyId,
    );

    _initLocation();
    _loadGeofences();
  }

  Future<void> _initLocation() async {
    debugPrint("🌐 Memulai fetch lokasi awal...");

    // Ambil lokasi awal
    final initialLocation = await _locationService.fetchInitialLocation();

    if (initialLocation != null) {
      debugPrint(
        "✅ Lokasi awal berhasil didapat: ${initialLocation.latitude}, ${initialLocation.longitude}",
      );
      setState(() {
        _childLocation = initialLocation;
        _isLocationLoaded = true;
      });

      // Jika map sudah ready, langsung move ke lokasi baru
      if (_isMapReady) {
        _mapController.move(_childLocation, 14);
        debugPrint(
          "🗺️ Map dipindah ke lokasi: ${_childLocation.latitude}, ${_childLocation.longitude}",
        );
      }
    } else {
      debugPrint(
        "⚠️ Gagal mendapatkan lokasi awal dari API, pakai default: ${_childLocation.latitude}, ${_childLocation.longitude}",
      );
      setState(() {
        _isLocationLoaded = true;
      });
    }

    debugPrint("⚡️ Memulai inisialisasi Pusher...");
    // Inisialisasi Pusher
    await _locationService.initPusher(
      onLocationUpdated: (newLoc) {
        debugPrint(
          "📡 Event location.updated diterima: ${newLoc.latitude}, ${newLoc.longitude}",
        );
        setState(() {
          _childLocation = newLoc;
        });

        if (_isMapReady) {
          _mapController.move(_childLocation, _mapController.camera.zoom);
          debugPrint(
            "🗺️ Map dipindah ke lokasi update: ${newLoc.latitude}, ${newLoc.longitude}",
          );
        }
      },
    );
  }

  Future<void> _loadGeofences() async {
    debugPrint("🔄 Memuat geofences...");

    try {
      final geofences = await _geofenceService.getGeofences();

      if (geofences != null) {
        debugPrint("✅ Berhasil memuat ${geofences.length} geofences");
        setState(() {
          _geofences = geofences;
          _areGeofencesLoaded = true;
        });
      } else {
        debugPrint("⚠️ Tidak ada geofences yang ditemukan");
        setState(() {
          _areGeofencesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("❌ Error memuat geofences: $e");
      setState(() {
        _areGeofencesLoaded = true;
      });
    }
  }

  // Method to get current child location for external use
  LatLng get currentChildLocation => _childLocation;

  @override
  void dispose() {
    _locationService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            (_isLocationLoaded && _areGeofencesLoaded)
                ? FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _childLocation,
                    initialZoom: 14,
                    onMapReady: () {
                      setState(() => _isMapReady = true);

                      // Pastikan map berada di lokasi yang benar setelah ready
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mapController.move(_childLocation, 14);
                        debugPrint(
                          "🗺️ Map ready dan dipindah ke: ${_childLocation.latitude}, ${_childLocation.longitude}",
                        );
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    // Geofence circles
                    CircleLayer(
                      circles:
                          _geofences
                              .map(
                                (geofence) => CircleMarker(
                                  point: LatLng(
                                    geofence.centerLatitude,
                                    geofence.centerLongitude,
                                  ),
                                  radius: geofence.radius.toDouble(),
                                  useRadiusInMeter: true,
                                  color:
                                      geofence.type == 'safe'
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                  borderColor:
                                      geofence.type == 'safe'
                                          ? Colors.green
                                          : Colors.red,
                                  borderStrokeWidth: 2,
                                ),
                              )
                              .toList(),
                    ),
                    // Geofence markers
                    MarkerLayer(
                      markers: [
                        // Child location marker
                        Marker(
                          point: _childLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        // Geofence center markers
                        ..._geofences.map(
                          (geofence) => Marker(
                            point: LatLng(
                              geofence.centerLatitude,
                              geofence.centerLongitude,
                            ),
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    geofence.type == 'safe'
                                        ? Icons.shield
                                        : Icons.warning,
                                    color:
                                        geofence.type == 'safe'
                                            ? Colors.green
                                            : Colors.red,
                                    size: 16,
                                  ),
                                  Text(
                                    geofence.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : const Center(
                  child: ParentalControlLoading(
                    primaryColor: AppColors.primary,
                    type: LoadingType.family,
                    message: "Loading...",
                  ),
                ),
      ),
    );
  }
}
