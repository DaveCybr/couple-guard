import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/geofence_service.dart';
import '../models/geofence_model.dart';
import './loading_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../services/location_service.dart';

class GeofenceScreen extends StatefulWidget {
  final String authToken;
  final String familyId;
  final LatLng? initialLocation;

  const GeofenceScreen({
    Key? key,
    required this.familyId,
    required this.authToken,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _selectedLocation;
  double _selectedRadius = 100.0;
  bool _isLoading = false;
  bool _isMapReady = false;
  bool _isSearching = false;
  bool _isInitializing = true;
  List<LocationSearchResult> _searchResults = [];

  // 🎯 Tambahan: List geofence yang sudah ada
  List<GeofenceModel> _existingGeofences = [];
  bool _areGeofencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ??
        const LatLng(-6.200000, 106.816666); // Default Jakarta
    _radiusController.text = _selectedRadius.toString();
    _initializeLocation();
    _loadExistingGeofences(); // Load geofences yang sudah ada
  }

  Future<void> _initializeLocation() async {
    LatLng locationToUse;

    if (widget.initialLocation != null) {
      locationToUse = widget.initialLocation!;
      debugPrint(
        "🎯 Menggunakan initial location: ${locationToUse.latitude}, ${locationToUse.longitude}",
      );
    } else {
      debugPrint("🔍 Mencari lokasi terakhir...");

      final locationService = LocationPusherService(
        familyId: widget.familyId,
        authToken: widget.authToken,
      );

      final lastLocation = await locationService.fetchInitialLocation();

      if (lastLocation != null) {
        locationToUse = lastLocation;
        debugPrint(
          "✅ Menggunakan lokasi terakhir: ${locationToUse.latitude}, ${locationToUse.longitude}",
        );
      } else {
        locationToUse = const LatLng(-6.200000, 106.816666);
        debugPrint(
          "⚠️ Menggunakan lokasi default: ${locationToUse.latitude}, ${locationToUse.longitude}",
        );
      }

      locationService.dispose();
    }

    setState(() {
      _selectedLocation = locationToUse;
      _isInitializing = false;
    });

    if (_isMapReady) {
      _mapController.move(_selectedLocation, 14);
    }
  }

  // 🎯 Load geofences yang sudah ada
  Future<void> _loadExistingGeofences() async {
    debugPrint("🔄 Memuat geofences yang sudah ada...");

    try {
      final geofenceService = GeofenceService(authToken: widget.authToken);
      final geofences = await geofenceService.getGeofences();

      if (geofences != null && geofences.isNotEmpty) {
        debugPrint("✅ Berhasil memuat ${geofences.length} geofences");
        setState(() {
          _existingGeofences = geofences;
          _areGeofencesLoaded = true;
        });
      } else {
        debugPrint("⚠️ Tidak ada geofences yang ditemukan");
        setState(() {
          _existingGeofences = [];
          _areGeofencesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("❌ Error memuat geofences: $e");
      setState(() {
        _existingGeofences = [];
        _areGeofencesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    debugPrint('Selected location: ${point.latitude}, ${point.longitude}');
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=id',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ParentalControlApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _searchResults = data
              .map((item) => LocationSearchResult.fromJson(item))
              .toList();
        });
      } else {
        debugPrint('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(LocationSearchResult result) {
    setState(() {
      _selectedLocation = LatLng(result.latitude, result.longitude);
      _searchResults = [];
      _searchController.clear();
    });

    if (_isMapReady) {
      _mapController.move(_selectedLocation, 16);
    }
  }

  Future<void> _saveGeofence() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama geofence harus diisi')),
      );
      return;
    }

    final radius = double.tryParse(_radiusController.text);
    if (radius == null || radius < 10 || radius > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Radius harus antara 10-50000 meter')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final geofenceService = GeofenceService(authToken: widget.authToken);

      final success = await geofenceService.createGeofence(
        name: _nameController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        radius: radius.toInt(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geofence berhasil disimpan!')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan geofence')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Geofence'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isInitializing
          ? const Center(
              child: ParentalControlLoading(
                primaryColor: AppColors.primary,
                type: LoadingType.family,
                message: "Memuat lokasi...",
              ),
            )
          : Column(
              children: [
                // Map Section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 14,
                              onTap: _onMapTap,
                              onMapReady: () {
                                setState(() => _isMapReady = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _mapController.move(_selectedLocation, 14);
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              // 🎯 EXISTING GEOFENCES - Tampilkan geofence yang sudah ada
                              if (_existingGeofences.isNotEmpty)
                                CircleLayer(
                                  circles: _existingGeofences
                                      .map(
                                        (geofence) => CircleMarker(
                                          point: LatLng(
                                            geofence.latitude,
                                            geofence.longitude,
                                          ),
                                          radius: geofence.radius.toDouble(),
                                          useRadiusInMeter: true,
                                          color: Colors.blue.withOpacity(0.15),
                                          borderColor: Colors.blue,
                                          borderStrokeWidth: 2,
                                        ),
                                      )
                                      .toList(),
                                ),
                              // 🆕 NEW GEOFENCE - Geofence baru yang sedang dibuat (hijau)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _selectedLocation,
                                    radius: _selectedRadius,
                                    useRadiusInMeter: true,
                                    color: Colors.green.withOpacity(0.3),
                                    borderColor: Colors.green,
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                              // 📍 MARKERS
                              MarkerLayer(
                                markers: [
                                  // Marker geofence yang sudah ada (biru)
                                  if (_existingGeofences.isNotEmpty)
                                    ..._existingGeofences.map(
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
                                              color: Colors.blue,
                                              size: 28,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                geofence.name,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Marker geofence baru (hijau)
                                  Marker(
                                    point: _selectedLocation,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.green,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Search bar di atas peta
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    Future.delayed(
                                      const Duration(milliseconds: 500),
                                      () {
                                        if (_searchController.text == value) {
                                          _searchLocation(value);
                                        }
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Cari lokasi...',
                                    prefixIcon: _isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.search),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchResults = [];
                                              });
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),

                              // Search results
                              if (_searchResults.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final result = _searchResults[index];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.location_on,
                                          size: 20,
                                        ),
                                        title: Text(
                                          result.displayName,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () =>
                                            _selectSearchResult(result),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 🎯 Legend di kiri bawah
                        if (_existingGeofences.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.3),
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_existingGeofences.length} Existing',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.3),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'New',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Form Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _existingGeofences.isNotEmpty
                                        ? 'Biru = Geofence lama, Hijau = Geofence baru'
                                        : 'Gunakan pencarian atau tap pada peta untuk memilih lokasi',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Current location info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Name field
                          const Text(
                            'Nama Geofence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Contoh: Rumah, Sekolah, dll',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Radius field
                          const Text(
                            'Radius (meter)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _radiusController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final radius = double.tryParse(value);
                              if (radius != null) {
                                setState(() {
                                  _selectedRadius = radius;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Masukkan radius (10-50000)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveGeofence,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      'Simpan Geofence',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Model untuk hasil pencarian lokasi
class LocationSearchResult {
  final double latitude;
  final double longitude;
  final String displayName;

  LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      displayName: json['display_name'].toString(),
    );
  }
}
