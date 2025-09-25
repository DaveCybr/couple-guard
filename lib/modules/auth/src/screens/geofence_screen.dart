import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/geofence_service.dart';
import './loading_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../services/location_service.dart';

class GeofenceScreen extends StatefulWidget {
  final int familyId;
  final String authToken;
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
  String _selectedType = 'safe';
  bool _isLoading = false;
  bool _isMapReady = false;
  bool _isSearching = false;
  bool _isInitializing = true;
  List<LocationSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ??
        const LatLng(-6.200000, 106.816666); // Default Jakarta
    _radiusController.text = _selectedRadius.toString();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    LatLng locationToUse;

    // Prioritas lokasi:
    // 1. initialLocation yang diberikan dari parameter
    // 2. Lokasi terakhir anak dari LocationService
    // 3. Default Jakarta

    if (widget.initialLocation != null) {
      locationToUse = widget.initialLocation!;
      debugPrint(
        "🎯 Menggunakan initial location: ${locationToUse.latitude}, ${locationToUse.longitude}",
      );
    } else {
      debugPrint("🔍 Mencari lokasi terakhir anak...");

      final locationService = LocationPusherService(
        authToken: widget.authToken,
        familyId: widget.familyId,
      );

      final childLastLocation = await locationService.fetchInitialLocation();

      if (childLastLocation != null) {
        locationToUse = childLastLocation;
        debugPrint(
          "✅ Menggunakan lokasi terakhir anak: ${locationToUse.latitude}, ${locationToUse.longitude}",
        );
      } else {
        locationToUse = const LatLng(-6.200000, 106.816666); // Default Jakarta
        debugPrint(
          "⚠️ Menggunakan lokasi default: ${locationToUse.latitude}, ${locationToUse.longitude}",
        );
      }
    }

    setState(() {
      _selectedLocation = locationToUse;
      _isInitializing = false;
    });

    // Jika map sudah ready, move ke lokasi yang telah ditentukan
    if (_isMapReady) {
      _mapController.move(_selectedLocation, 14);
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
      // Menggunakan Nominatim (OpenStreetMap) untuk pencarian gratis
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
          _searchResults =
              data.map((item) => LocationSearchResult.fromJson(item)).toList();
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
      final geofenceService = GeofenceService(
        authToken: widget.authToken,
        familyId: widget.familyId,
      );

      final success = await geofenceService.createGeofence(
        name: _nameController.text.trim(),
        centerLatitude: _selectedLocation.latitude,
        centerLongitude: _selectedLocation.longitude,
        radius: radius.toInt(),
        type: _selectedType,
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
      body:
          _isInitializing
              ? const Center(
                child: ParentalControlLoading(
                  primaryColor: AppColors.primary,
                  type: LoadingType.family,
                  message: "Memuat lokasi...",
                ),
              )
              : Column(
                children: [
                  // Map Section - Diperkecil menjadi 35% dari layar
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
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _selectedLocation,
                                      radius: _selectedRadius,
                                      useRadiusInMeter: true,
                                      color:
                                          _selectedType == 'safe'
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                      borderColor:
                                          _selectedType == 'safe'
                                              ? Colors.green
                                              : Colors.red,
                                      borderStrokeWidth: 2,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation,
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.location_pin,
                                        color:
                                            _selectedType == 'safe'
                                                ? Colors.green
                                                : Colors.red,
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
                                      // Debounce search
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
                                      prefixIcon:
                                          _isSearching
                                              ? const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap:
                                              () => _selectSearchResult(result),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form Section - Mengambil sisa ruang
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
                              child: const Text(
                                'Gunakan pencarian atau tap pada peta untuk memilih lokasi geofence',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
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
                                    color: Colors.blue,
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

                            const SizedBox(height: 16),

                            // Type selection
                            const Text(
                              'Tipe Geofence',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Aman'),
                                    value: 'safe',
                                    groupValue: _selectedType,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Bahaya'),
                                    value: 'danger',
                                    groupValue: _selectedType,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
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
                                child:
                                    _isLoading
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

                            const SizedBox(height: 35), // Extra padding
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
