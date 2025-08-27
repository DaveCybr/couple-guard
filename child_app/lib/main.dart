import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// ================== KONFIG APP ==================
/// Ganti sesuai kebutuhan (bisa di-generate saat pairing QR).
const String kChildId = "child_dhafa_001";
const String kParentId = "parent_main";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const ChildLocatorApp());
}

class ChildLocatorApp extends StatelessWidget {
  const ChildLocatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Child Locator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056F1)),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Timers untuk background tasks
  Timer? _locationTimer;
  Timer? _heartbeatTimer;
  Timer? _batteryTimer;

  // Subscriptions
  StreamSubscription<ConnectivityResult>? _netSub;
  StreamSubscription<DocumentSnapshot>? _commandsSub;

  // State variables
  String _status = 'Memulai sistem tracking...';
  Position? _lastPosition;
  DateTime? _lastSent;
  ConnectivityResult _net = ConnectivityResult.none;
  int _batteryLevel = 100;
  bool _isActive = false;
  int _locationsSent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  /// App lifecycle monitoring
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _sendAppStateUpdate(state.name);
  }

  /// Initialize all background services
  Future<void> _initializeApp() async {
    await _initConnectivity();
    await _ensurePermissions();
    await _startBackgroundServices();
    await _listenForParentCommands();

    // Send initial status
    await _sendAppStateUpdate('initialized');

    setState(() {
      _isActive = true;
      _status = 'Sistem tracking aktif';
    });
  }

  /// Setup connectivity monitoring
  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _net = results.isNotEmpty ? results.first : ConnectivityResult.none;

    Connectivity().onConnectivityChanged.listen((results) {
      final newNet =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (_net != newNet) {
        setState(() => _net = newNet);
        _sendNetworkChangeEvent(_net, newNet);
      }
    });
  }

  /// Ensure all required permissions
  Future<void> _ensurePermissions() async {
    // Check location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'GPS/Location Service tidak aktif');
      return;
    }

    // Request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Izin lokasi ditolak permanen');
      return;
    }

    // For Android 10+, request background location
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always) {
      setState(() => _status = 'Izin lokasi: Always (Optimal)');
    } else {
      setState(() => _status = 'Izin lokasi: While in use');
    }
  }

  /// Start all background services
  Future<void> _startBackgroundServices() async {
    // Location timer - setiap 10 menit
    _locationTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _getCurrentLocationAndSend();
    });

    // Heartbeat timer - setiap 2 menit
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _sendHeartbeat();
    });

    // Battery monitoring - setiap 5 menit
    _batteryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _getBatteryLevel();
    });

    // Send first location immediately
    await _getCurrentLocationAndSend();
    await _getBatteryLevel();
  }

  /// Listen for real-time commands from parent
  Future<void> _listenForParentCommands() async {
    final commandDoc = FirebaseFirestore.instance
        .collection('children')
        .doc(kChildId)
        .collection('commands')
        .doc('current');

    _commandsSub = commandDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _handleParentCommand(data);
      }
    });
  }

  /// Handle commands from parent app
  Future<void> _handleParentCommand(Map<String, dynamic> command) async {
    final action = command['action'] as String?;
    final timestamp = command['timestamp'] as String?;
    final requestId = command['request_id'] as String?;

    // Ignore old commands (older than 5 minutes)
    if (timestamp != null) {
      final commandTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(commandTime).inMinutes > 5) {
        return;
      }
    }

    switch (action) {
      case 'get_location_now':
        await _getCurrentLocationAndSend(
          isRequestedByParent: true,
          requestId: requestId,
        );
        setState(() => _status = 'Lokasi dikirim atas permintaan orang tua');
        break;
      case 'increase_frequency':
        _adjustLocationFrequency(const Duration(minutes: 5));
        break;
      case 'decrease_frequency':
        _adjustLocationFrequency(const Duration(minutes: 15));
        break;
      case 'reset_frequency':
        _adjustLocationFrequency(const Duration(minutes: 10));
        break;
    }

    // Mark command as processed
    await _markCommandAsProcessed(requestId);
  }

  /// Adjust location tracking frequency
  void _adjustLocationFrequency(Duration newInterval) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(newInterval, (_) {
      _getCurrentLocationAndSend();
    });

    setState(
      () =>
          _status = 'Frekuensi tracking diubah: ${newInterval.inMinutes} menit',
    );
  }

  /// Mark parent command as processed
  Future<void> _markCommandAsProcessed(String? requestId) async {
    if (requestId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(kChildId)
          .collection('commands')
          .doc('current')
          .update({
            'processed': true,
            'processed_at': DateTime.now().toUtc().toIso8601String(),
            'processed_by': kChildId,
          });
    } catch (e) {
      debugPrint('Error marking command as processed: $e');
    }
  }

  /// Get current location with fallback strategies
  Future<void> _getCurrentLocationAndSend({
    bool isRequestedByParent = false,
    String? requestId,
  }) async {
    Position? position;
    String accuracy = 'unknown';

    try {
      // Strategy 1: High accuracy (15s timeout)
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      accuracy = 'high';
    } catch (e) {
      try {
        // Strategy 2: Medium accuracy (30s timeout)
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 30),
        );
        accuracy = 'medium';
      } catch (e) {
        try {
          // Strategy 3: Low accuracy (60s timeout)
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 60),
          );
          accuracy = 'low';
        } catch (e) {
          // Strategy 4: Last known position
          position = await Geolocator.getLastKnownPosition();
          accuracy = 'cached';
        }
      }
    }

    if (position != null) {
      _lastPosition = position;
      await _uploadPosition(position, accuracy, isRequestedByParent, requestId);
      setState(() {
        _locationsSent++;
        _status =
            isRequestedByParent
                ? 'Lokasi dikirim atas permintaan orang tua'
                : 'Lokasi terkirim otomatis (#$_locationsSent)';
      });
    } else {
      setState(() => _status = 'Gagal mendapatkan lokasi');
    }
  }

  /// Upload position to Firestore
  Future<void> _uploadPosition(
    Position position,
    String accuracy,
    bool isRequestedByParent,
    String? requestId,
  ) async {
    final now = DateTime.now().toUtc();

    final data = {
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy_m': position.accuracy,
      'accuracy_level': accuracy,
      'speed_mps': position.speed,
      'heading_deg': position.heading,
      'alt_m': position.altitude,
      'timestamp': now.toIso8601String(),
      'network': _net.name,
      'child_id': kChildId,
      'battery_level': _batteryLevel,
      'is_moving': position.speed > 0.5,
      'requested_by_parent': isRequestedByParent,
      'request_id': requestId,
    };

    // Retry mechanism
    int retries = 3;
    while (retries > 0) {
      try {
        final futures = <Future>[];

        // Always save to history
        futures.add(
          FirebaseFirestore.instance
              .collection('children')
              .doc(kChildId)
              .collection('locations')
              .add(data),
        );

        // Always update latest position
        futures.add(
          FirebaseFirestore.instance
              .collection('children')
              .doc(kChildId)
              .collection('latest')
              .doc('position')
              .set(data, SetOptions(merge: true)),
        );

        // If requested by parent, also save to parent_requests
        if (isRequestedByParent && requestId != null) {
          futures.add(
            FirebaseFirestore.instance
                .collection('children')
                .doc(kChildId)
                .collection('parent_requests')
                .doc(requestId)
                .set(data, SetOptions(merge: true)),
          );
        }

        await Future.wait(futures);
        _lastSent = now;
        break;
      } catch (e) {
        retries--;
        debugPrint('Upload error (retries left: $retries): $e');
        if (retries > 0) {
          await Future.delayed(Duration(seconds: 2 * (4 - retries)));
        }
      }
    }
  }

  /// Send heartbeat to show app is alive
  Future<void> _sendHeartbeat() async {
    final data = {
      'child_id': kChildId,
      'status': 'alive',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'battery_level': _batteryLevel,
      'network': _net.name,
      'locations_sent': _locationsSent,
      'last_location':
          _lastPosition != null
              ? {
                'lat': _lastPosition!.latitude,
                'lng': _lastPosition!.longitude,
                'timestamp': _lastSent?.toIso8601String(),
              }
              : null,
    };

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(kChildId)
          .collection('heartbeat')
          .doc('status')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Heartbeat error: $e');
    }
  }

  /// Send app state updates
  Future<void> _sendAppStateUpdate(String state) async {
    final data = {
      'child_id': kChildId,
      'app_state': state,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'battery_level': _batteryLevel,
    };

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(kChildId)
          .collection('app_events')
          .add(data);
    } catch (e) {
      debugPrint('App state update error: $e');
    }
  }

  /// Send network change event
  Future<void> _sendNetworkChangeEvent(
    ConnectivityResult old,
    ConnectivityResult newNet,
  ) async {
    final data = {
      'child_id': kChildId,
      'event_type': 'network_change',
      'old_network': old.name,
      'new_network': newNet.name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(kChildId)
          .collection('events')
          .add(data);
    } catch (e) {
      debugPrint('Network change error: $e');
    }
  }

  /// Get battery level
  Future<void> _getBatteryLevel() async {
    try {
      const platform = MethodChannel('battery');
      final int result = await platform.invokeMethod('getBatteryLevel');
      setState(() => _batteryLevel = result);
    } catch (e) {
      _batteryLevel = -1;
    }
  }

  /// Cleanup all resources
  void _cleanup() {
    _locationTimer?.cancel();
    _heartbeatTimer?.cancel();
    _batteryTimer?.cancel();
    _netSub?.cancel();
    _commandsSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header with child info
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                _isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Text(
                                  '👦',
                                  style: TextStyle(fontSize: 42),
                                ),
                                if (_isActive)
                                  Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Halo, Dhafa!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Child ID: $kChildId',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Status section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _isActive
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isActive
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _isActive ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status Tracking',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_status, style: theme.textTheme.bodyMedium),
                          if (_locationsSent > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Lokasi terkirim: $_locationsSent kali',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Last location info
                    if (_lastPosition != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Terakhir',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${_lastPosition!.latitude.toStringAsFixed(6)}\n'
                              'Lng: ${_lastPosition!.longitude.toStringAsFixed(6)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Akurasi: ${_lastPosition!.accuracy.toInt()}m',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16),
                                if (_lastSent != null)
                                  Text(
                                    'Dikirim: ${_formatTime(_lastSent!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Status indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Network status
                        _buildStatusChip(
                          icon: _getNetworkIcon(),
                          label: _net.name.toUpperCase(),
                          color:
                              _net == ConnectivityResult.none
                                  ? Colors.red
                                  : Colors.green,
                        ),
                        // Battery status
                        _buildStatusChip(
                          icon:
                              _batteryLevel < 20
                                  ? Icons.battery_alert
                                  : Icons.battery_std,
                          label: _batteryLevel >= 0 ? '$_batteryLevel%' : 'N/A',
                          color: _batteryLevel < 20 ? Colors.red : Colors.green,
                        ),
                        // Tracking status
                        _buildStatusChip(
                          icon: _isActive ? Icons.gps_fixed : Icons.gps_off,
                          label: _isActive ? 'AKTIF' : 'TIDAK AKTIF',
                          color: _isActive ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informasi Penting',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Aplikasi ini akan otomatis mengirim lokasi setiap 10 menit\n'
                            '• Orang tua dapat meminta lokasi kapan saja\n'
                            '• Pastikan GPS selalu aktif untuk hasil terbaik\n'
                            '• Jangan force-close aplikasi ini',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNetworkIcon() {
    switch (_net) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      default:
        return Icons.signal_wifi_off;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
