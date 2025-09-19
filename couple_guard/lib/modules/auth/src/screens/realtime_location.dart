import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
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
  LatLng _childLocation = const LatLng(-6.200000, 106.816666);
  bool _isMapReady = false;
  bool _isLocationLoaded = false; // Tambahkan flag ini

  @override
  void initState() {
    super.initState();

    _locationService = LocationPusherService(
      authToken: widget.authToken,
      familyId: widget.familyId,
    );

    _initLocation();
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
        _isLocationLoaded = true; // Set flag bahwa lokasi sudah loaded
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
        _isLocationLoaded = true; // Tetap set true meski pakai default
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
            _isLocationLoaded
                ? FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _childLocation, // Sekarang sudah benar
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
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _childLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
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
                    message: "Loading..",
                  ), // Loading saat fetch lokasi
                ),
      ),
    );
  }
}
