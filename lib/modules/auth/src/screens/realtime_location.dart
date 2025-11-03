// widgets/realtime_map_widget.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/geofence_service.dart';
import '../models/geofence_model.dart';
import './loading_screen.dart';
import '../../../../core/constants/app_colors.dart';

class RealtimeMapWidget extends StatefulWidget {
  final String familyId;
  final String authToken;
  final String? deviceId;

  const RealtimeMapWidget({
    Key? key,
    required this.familyId,
    required this.authToken,
    this.deviceId,
  }) : super(key: key);

  @override
  State<RealtimeMapWidget> createState() => RealtimeMapWidgetState();
}

class RealtimeMapWidgetState extends State<RealtimeMapWidget> {
  final MapController _mapController = MapController();
  late LocationPusherService _locationService;
  late GeofenceService _geofenceService;
  LatLng _childLocation = const LatLng(-6.200000, 106.816666);
  List<GeofenceModel> _geofences = [];
  bool _isMapReady = false;
  bool _isLocationLoaded = false;
  bool _areGeofencesLoaded = false;
  bool _isPusherConnected = false;

  @override
  void initState() {
    super.initState();

    _locationService = LocationPusherService(
      authToken: widget.authToken,
      familyId: widget.familyId,
    );

    _geofenceService = GeofenceService(authToken: widget.authToken);

    _initLocation();
    _loadGeofences();
  }

  Future<void> _initLocation() async {
    debugPrint("🌐 Memulai fetch lokasi awal...");

    try {
      final initialLocation = await _locationService.fetchInitialLocation();

      if (initialLocation != null) {
        debugPrint(
          "✅ Lokasi awal berhasil didapat: ${initialLocation.latitude}, ${initialLocation.longitude}",
        );
        setState(() {
          _childLocation = initialLocation;
          _isLocationLoaded = true;
        });

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

      await _locationService.initPusher(
        onLocationUpdated: (newLocation) {
          debugPrint(
            "📡 Event location.updated diterima: ${newLocation.latitude}, ${newLocation.longitude}",
          );

          setState(() {
            _childLocation = newLocation;
            _isPusherConnected = true;
          });

          if (_isMapReady) {
            _mapController.move(_childLocation, _mapController.camera.zoom);
            debugPrint(
              "🗺️ Map dipindah ke lokasi update: ${newLocation.latitude}, ${newLocation.longitude}",
            );
          }
        },
      );

      if (widget.deviceId != null) {
        await _locationService.subscribeToDevice(widget.deviceId!);
        debugPrint("✅ Subscribed to specific device: ${widget.deviceId}");
      }
    } catch (e) {
      debugPrint("❌ Error initializing location service: $e");
      setState(() {
        _isLocationLoaded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghubungkan ke layanan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGeofences() async {
    debugPrint("🔄 Memuat geofences...");

    try {
      final geofences = await _geofenceService.getGeofences();

      if (geofences != null && geofences.isNotEmpty) {
        debugPrint("✅ Berhasil memuat ${geofences.length} geofences");
        setState(() {
          _geofences = geofences;
          _areGeofencesLoaded = true;
        });
      } else {
        debugPrint("⚠️ Tidak ada geofences yang ditemukan");
        setState(() {
          _geofences = [];
          _areGeofencesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("❌ Error memuat geofences: $e");
      setState(() {
        _geofences = [];
        _areGeofencesLoaded = true;
      });
    }
  }

  Future<void> refreshLocation() async {
    debugPrint("🔄 Manual refresh location...");
    final location = await _locationService.fetchInitialLocation();
    if (location != null && mounted) {
      setState(() {
        _childLocation = location;
      });
      if (_isMapReady) {
        _mapController.move(_childLocation, 14);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi diperbarui: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui lokasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Public method untuk refresh geofences dari luar
  Future<void> refreshGeofences() async {
    await _loadGeofences();
  }

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
        child: Stack(
          children: [
            (_isLocationLoaded && _areGeofencesLoaded)
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _childLocation,
                      initialZoom: 14,
                      onMapReady: () {
                        setState(() => _isMapReady = true);

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
                      // 🎯 GEOFENCE CIRCLES - Ditampilkan dengan jelas
                      if (_geofences.isNotEmpty)
                        CircleLayer(
                          circles: _geofences
                              .map(
                                (geofence) => CircleMarker(
                                  point: LatLng(
                                    geofence.latitude,
                                    geofence.longitude,
                                  ),
                                  radius: geofence.radius.toDouble(),
                                  useRadiusInMeter: true,
                                  color: Colors.green.withOpacity(0.25),
                                  borderColor: Colors.green,
                                  borderStrokeWidth: 2,
                                ),
                              )
                              .toList(),
                        ),
                      // 📍 MARKER LAYER
                      MarkerLayer(
                        markers: [
                          // Marker lokasi anak (child)
                          Marker(
                            point: _childLocation,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.person_pin_circle,
                              color: _isPusherConnected
                                  ? Colors.blue
                                  : Colors.grey,
                              size: 40,
                            ),
                          ),
                          // Marker geofences dengan label
                          if (_geofences.isNotEmpty)
                            ..._geofences.map(
                              (geofence) => Marker(
                                point: LatLng(
                                  geofence.latitude,
                                  geofence.longitude,
                                ),
                                width: 70,
                                height: 50,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.green,
                                      size: 30,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        geofence.name,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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

            // Live indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPusherConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: _isPusherConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPusherConnected ? 'Live' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isPusherConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Geofence counter (jika ada geofence)
            if (_geofences.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${_geofences.length} Geofence',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Refresh button
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                onPressed: refreshLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.refresh, color: Colors.blue, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
