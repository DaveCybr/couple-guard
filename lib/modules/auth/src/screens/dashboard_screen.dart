import 'package:couple_guard/modules/auth/src/screens/album_camera_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/camera_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/family_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/geofence_list_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/loading_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import 'dart:ui' as ui;
import '../services/family_service.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/command_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './realtime_location.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './album_camera_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class WaveClipper extends CustomClipper<ui.Path> {
  final double waveHeight;

  WaveClipper({this.waveHeight = 40});

  @override
  ui.Path getClip(Size size) {
    ui.Path path = ui.Path();

    // Mulai dari pojok kiri atas
    path.lineTo(0, size.height - waveHeight);

    // Wave pertama
    path.cubicTo(
      size.width * 0.15,
      size.height - (waveHeight - 20),
      size.width * 0.25,
      size.height - (waveHeight + 5),
      size.width * 0.4,
      size.height - (waveHeight - 5),
    );

    // Wave kedua
    path.cubicTo(
      size.width * 0.55,
      size.height - (waveHeight - 15),
      size.width * 0.7,
      size.height - (waveHeight + 10),
      size.width * 0.85,
      size.height - (waveHeight - 10),
    );

    // Wave terakhir
    path.cubicTo(
      size.width * 0.92,
      size.height - (waveHeight - 20),
      size.width * 0.97,
      size.height - (waveHeight - 25),
      size.width,
      size.height - waveHeight,
    );

    // Tutup path dengan benar
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false; // Ubah ke false untuk performa
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      child: Stack(
        children: [
          // Background gradient dengan wave
          ClipPath(
            clipper: WaveClipper(waveHeight: 20), // Kurangi tinggi wave
            child: Container(
              height: preferredSize.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4A85F6), // lebih terang dari base
                    Color(0xFF0056F1), // base color
                    Color(0xFF003C9D), // lebih gelap dari base
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Konten AppBar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(
                                  'https://ui-avatars.com/api/?name=&background=random&color=fff&size=128',
                                ),
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                      // Handle error jika gagal load image
                                    },
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Parent",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    auth.user?.email ?? "user@email.com",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130); // Kurangi tinggi AppBar
}

class BottomNavBackgroundPainter extends CustomPainter {
  final double activeIndex;
  final int totalItems;

  BottomNavBackgroundPainter({required this.activeIndex, this.totalItems = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.25) // warna shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = ui.Path();

    final double itemWidth = size.width / totalItems;
    final double centerX = itemWidth * activeIndex + itemWidth / 2;
    final double curveRadius = 33;
    final double curveHeight = 33;

    path.lineTo(centerX - curveRadius * 2, 0);

    // Lengkung ke atas
    path.cubicTo(
      centerX - curveRadius,
      0,
      centerX - curveRadius,
      -curveHeight,
      centerX,
      -curveHeight,
    );

    path.cubicTo(
      centerX + curveRadius,
      -curveHeight,
      centerX + curveRadius,
      0,
      centerX + curveRadius * 2,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // 🔥 Shadow ke atas: kita geser path sedikit ke bawah,
    // jadi efek blur-nya muncul di bagian atas
    canvas.save();
    canvas.translate(0, 4); // atur jarak shadow ke atas
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Background putih
    canvas.drawPath(path, bgPaint);
  }

  @override
  bool shouldRepaint(covariant BottomNavBackgroundPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex;
  }
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  int? selectedChild;
  late AnimationController _animationController;
  late Animation<double> _curveAnimation;
  String? _authToken;
  final FamilyService _familyService = FamilyService();
  List<GetFamily> _families = [];
  bool _isLoading = false;
  List<NotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;
  Map<String, dynamic>? _pagination;
  Map<String, dynamic>? _summary;
  List<DeviceModel> _devices = [];
  bool _isLoadingDevices = false;
  String? _selectedDeviceId;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final GlobalKey<RealtimeMapWidgetState> _mapWidgetKey = GlobalKey();
  final LocalNotificationService _localNotification =
      LocalNotificationService();
  final CommandService commandService = CommandService();

  Future<void> _handleMonitoring(String deviceId, String token) async {
    print("ditap$deviceId");
    try {
      final result = await commandService.startMonitoring(
        deviceId: deviceId,
        authToken: token,
      );
      print('monitoring requested: ${result['success']}');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleCapturePhoto(String deviceId, String token) async {
    print("ditap$deviceId");

    // Snackbar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mengambil foto...', style: TextStyle(fontSize: 15)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    try {
      final result = await commandService.capturePhoto(
        deviceId: deviceId,
        authToken: token,
      );

      print('Photo captured: ${result['success']}');

      // Snackbar success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Foto berhasil diambil! 📸',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lihat di menu Album Potretan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');

      // Snackbar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gagal mengambil foto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () {
                _handleCapturePhoto(deviceId, token);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleMonitoringScreen(String deviceId, String token) async {
    print("ditap$deviceId");

    try {
      final result = await commandService.startScreenMonitor(
        deviceId: deviceId,
        authToken: token,
      );
      print('Location requested: ${result['success']}');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleRequestLocation(String deviceId, String token) async {
    print("ditap$deviceId");
    print("ditap$_authToken");

    // Snackbar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Meminta lokasi perangkat...',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    try {
      final result = await commandService.requestLocation(
        deviceId: deviceId,
        authToken: token,
      );

      print('Location requested: ${result['success']}');

      // Snackbar success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Permintaan lokasi berhasil dikirim!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');

      // Snackbar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gagal meminta lokasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () {
                _handleRequestLocation(deviceId, token);
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> fetchAppIcon(String packageName) async {
    final apiKey =
        "c8c3e9d70793274cd329b8523d5bad7383c8b1c7b0b65250d8cb1b41e3d0c686";
    final url =
        "https://serpapi.com/search.json?engine=google_play&q=$packageName&api_key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 1️⃣ Cek app_highlight
        String? thumbnail = data['app_highlight']?['thumbnail'];

        // 2️⃣ Kalau null, cek organic_results
        if (thumbnail == null &&
            data['organic_results'] != null &&
            data['organic_results'] is List &&
            data['organic_results'].isNotEmpty) {
          final items = data['organic_results'][0]['items'];
          if (items != null && items is List && items.isNotEmpty) {
            thumbnail = items[0]['thumbnail'];
          }
        }

        print("Package: $packageName, Thumbnail: $thumbnail");

        if (thumbnail != null && thumbnail is String) {
          return thumbnail;
        }
      } else {
        print("Failed to fetch $packageName: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching $packageName: $e");
    }

    return null;
  }

  Future<void> _loadNotifications(String deviceId) async {
    if (_authToken == null) {
      debugPrint("❌ Tidak ada auth token, skip load notifications");
      return;
    }

    setState(() {
      _isLoadingNotifications = true;
    });

    debugPrint("🔄 ===== START LOAD NOTIFICATIONS =====");
    debugPrint("📱 Selected Device ID: $deviceId");
    debugPrint(
      "👤 User ID: ${Provider.of<AuthProvider>(context, listen: false).user?.id}",
    );
    debugPrint("🔐 Token available: ${_authToken != null}");
    debugPrint("📋 Total devices: ${_devices.length}");
    try {
      final result = await _notificationService.fetchNotifications(
        authToken: _authToken!,
        deviceId: deviceId, // Sekarang menggunakan device_id dari API devices
        limit: 50,
      );

      setState(() {
        _notifications = result['notifications'] as List<NotificationModel>;
      });

      debugPrint(
        "✅ Berhasil load ${_notifications.length} notifikasi untuk device $deviceId",
      );
    } catch (e) {
      debugPrint("❌ Error load notifications: $e");
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    if (_authToken == null) {
      debugPrint("❌ Token null, tidak bisa load devices");
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.id == null) {
      debugPrint("❌ User ID null, tidak bisa load devices");
      return;
    }

    setState(() => _isLoadingDevices = true);

    try {
      final devices = await _authService.getDevicesByParent(
        parentId: user!.id!,
        token: _authToken!,
      );

      setState(() {
        _devices = devices;

        if (devices.isNotEmpty && _selectedDeviceId == null) {
          // PASTIKAN menggunakan deviceId, bukan id
          _selectedDeviceId = devices.first.deviceId;
          debugPrint("✅ Selected device: ${_selectedDeviceId}");
          _loadNotifications(_selectedDeviceId!);
        }
      });

      debugPrint("✅ Berhasil load ${devices.length} devices");

      // DEBUG: Print semua device yang loaded
      for (var device in devices) {
        debugPrint('📱 Device: ${device.deviceName}');
        debugPrint(
          '   - deviceId: ${device.deviceId} (${device.deviceId.runtimeType})',
        );
        debugPrint('   - id: ${device.id} (${device.id.runtimeType})');
        debugPrint('   - isOnline: ${device.isOnline}');
      }
    } catch (e) {
      debugPrint("❌ Error load devices: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat devices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingDevices = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_authToken == null && authProvider.token != null) {
      setState(() {
        _authToken = authProvider.token;
      });
      _loadFamilies(); // panggil setelah token ada
      _loadDevices();
      // _loadNotifications(_selectedDeviceId!);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _curveAnimation =
        Tween<double>(
          begin: _selectedIndex.toDouble(),
          end: _selectedIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  Future<void> _loadFamilies() async {
    debugPrint("🔑 Auth token sekarang: $_authToken");
    if (_authToken == null) {
      debugPrint("❌ Token null, tidak bisa load families");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final families = await _familyService.getJoinedFamilies(
        authToken: _authToken!,
      );
      setState(() {
        _families = families;
      });
    } catch (e) {
      debugPrint("❌ Error load families: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onNavItemTapped(int newIndex) {
    final oldIndex = _selectedIndex;

    setState(() {
      _selectedIndex = newIndex;
    });

    _curveAnimation =
        Tween<double>(
          begin: oldIndex.toDouble(),
          end: newIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward(from: 0);
  }

  void _refreshLocationData(deviceId) async {
    if (_authToken == null || _selectedDeviceId == null) {
      _showErrorSnackBar('Silakan pilih device terlebih dahulu');
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mengirim permintaan lokasi...'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // // Panggil API request location
      // final locationService = LocationPusherService(
      //   authToken: _authToken!,
      //   familyId:
      //       _selectedDeviceId!, // gunakan deviceId di sini (sementara familyId di class)
      // );

      // // ✅ Panggil fungsi requestLocationUpdate tanpa parameter tambahan
      // final result = await locationService.requestLocationUpdate();

      final result = await commandService.requestLocation(
        deviceId: deviceId,
        authToken: _authToken!,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Berhasil, tunggu sebentar lalu refresh map
          await Future.delayed(const Duration(seconds: 2));

          // Refresh map widget jika ada
          if (_mapWidgetKey.currentState != null) {
            _mapWidgetKey.currentState!.refreshLocation();
          }

          _showSuccessSnackBar(
            result['message'] ?? 'Permintaan lokasi berhasil dikirim',
          );
        } else {
          _showErrorSnackBar(
            result['message'] ?? 'Gagal mengirim permintaan lokasi',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting location: $e');
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // Tambahkan helper function untuk success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchLatestLocation() async {
    try {
      final locationService = LocationPusherService(
        authToken: _authToken!,
        familyId: _selectedDeviceId!, // menggunakan deviceId sebagai familyId
      );

      final latestLocation = await locationService.fetchInitialLocation();

      if (latestLocation != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi diperbarui: ${latestLocation.latitude.toStringAsFixed(4)}, ${latestLocation.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger refresh pada map widget jika perlu
        // Anda bisa menggunakan GlobalKey atau callback untuk memanggil refresh pada RealtimeMapWidget
        debugPrint('✅ Lokasi terbaru berhasil diambil');
      } else {
        if (mounted) {
          _showErrorSnackBar('Gagal mendapatkan lokasi terbaru');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching latest location: $e');
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Lokasi dengan Map
          // Card Lokasi - Updated styling
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[50]!, Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Lokasi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map view pakai flutter_map
                        if (_authToken != null && _selectedDeviceId != null)
                          RealtimeMapWidget(
                            key: _mapWidgetKey, // reset state kalau ganti child
                            familyId: _selectedDeviceId!,
                            authToken: _authToken!,
                          )
                        else
                          _buildEmptyMapWidget(),
                        const SizedBox(height: 16),

                        // Tombol Geofence & Pembaruan
                        // Tombol Geofence & Pembaruan - Modern version
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                borderRadius: BorderRadius.circular(12),
                                elevation: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue[500]!,
                                        Colors.blue[600]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      if (_authToken != null &&
                                          _selectedDeviceId != null) {
                                        LatLng? currentLocation;
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GeofenceListScreen(
                                                  familyId: _selectedDeviceId!,
                                                  authToken: _authToken!,
                                                ),
                                          ),
                                        );
                                        if (result == true) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Geofence berhasil ditambahkan!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        _showErrorSnackBar(
                                          'Silakan login dan pilih anak terlebih dahulu',
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.fence_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Geofence",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Material(
                                borderRadius: BorderRadius.circular(12),
                                elevation: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[600]!,
                                        Colors.grey[700]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _handleRequestLocation(
                                        _selectedDeviceId!,
                                        _authToken!,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.refresh_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Pembaruan",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[50]!, Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: Colors.purple.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.purple[600]!],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Monitoring Visual',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content - Grid 2x2
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Baris pertama (2 menu atas)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMonitoringButton(
                                icon: Icons.photo_album_rounded,
                                label: 'Album\nPotretan',
                                color: Colors.blue,
                                gradientColors: [
                                  Colors.blue[400]!,
                                  Colors.blue[600]!,
                                ],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ScreenshotGalleryPage(
                                            deviceId: _selectedDeviceId!,
                                            authToken: _authToken!,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMonitoringButton(
                                icon: Icons.camera_alt_rounded,
                                label: 'Potretan\nSekali',
                                color: Colors.teal,
                                gradientColors: [
                                  Colors.teal[400]!,
                                  Colors.teal[600]!,
                                ],
                                onTap: () {
                                  _handleCapturePhoto(
                                    _selectedDeviceId!,
                                    _authToken!,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Baris kedua (2 menu bawah)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMonitoringButton(
                                icon: Icons.videocam_rounded,
                                label: 'Kamera\nLive',
                                color: Colors.purple,
                                gradientColors: [
                                  Colors.purple[400]!,
                                  Colors.purple[600]!,
                                ],
                                onTap: () {
                                  _handleMonitoring(
                                    _selectedDeviceId!,
                                    _authToken!,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMonitoringButton(
                                icon: Icons.screenshot_monitor_rounded,
                                label: 'Layar\nLive',
                                color: Colors.orange,
                                gradientColors: [
                                  Colors.orange[400]!,
                                  Colors.orange[600]!,
                                ],
                                onTap: () {
                                  _handleMonitoringScreen(
                                    _selectedDeviceId!,
                                    _authToken!,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Helper Widget untuk tombol monitoring
        ],
      ),
    );
  }

  Widget _buildMonitoringButton({
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyMapWidget() {
    return Container(
      height: 200, // Sama dengan RealtimeMapWidget
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background abu-abu terang
        borderRadius: BorderRadius.circular(
          16,
        ), // Sama dengan RealtimeMapWidget
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon map dengan garis coret
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey[500]),
                // Garis coret diagonal
                Transform.rotate(
                  angle: -0.785398, // -45 derajat dalam radian
                  child: Container(
                    width: 85,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text utama
            Text(
              'Select Family Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            // Text subtitle
            Text(
              'to view location on map',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesPage() {
    return Column(
      children: [
        // Device Button (jika ada device)
        if (_devices.isNotEmpty) _buildDeviceButton(),

        // Notifications List
        Expanded(child: _buildNotificationsList()),
      ],
    );
  }

  Widget _buildDeviceButton() {
    if (_devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Tidak ada device terdaftar. Pastikan device sudah terhubung.",
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final device = _devices.first; // Ambil device pertama (karena hanya 1)
    final isSelected = _selectedDeviceId == device.deviceId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDeviceId = device.deviceId;
                });
                debugPrint("🔄 Device selected: ${device.deviceId}");
                _loadNotifications(device.deviceId);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            device.deviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.blue[900]
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: device.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                device.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: device.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: Colors.blue, size: 20),
                  ],
                ),
              ),
            ),
          ),
          // const SizedBox(width: 8),
          // IconButton(
          //   icon: const Icon(Icons.refresh, size: 20),
          //   onPressed: _loadDevices,
          //   tooltip: "Refresh Devices",
          // ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_selectedDeviceId == null && _devices.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Tap device di atas untuk melihat notifikasi",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isLoadingNotifications) {
      return const Center(
        child: ParentalControlLoading(
          primaryColor: AppColors.primary,
          type: LoadingType.family,
          message: "Memuat notifikasi...",
        ),
      );
    }

    if (_notifications.isEmpty && _selectedDeviceId != null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Belum ada notifikasi",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Notifikasi akan muncul di sini",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group notifications by date (yyyy/MM/dd)
    final Map<String, List<NotificationModel>> notificationsByDate = {};
    for (var n in _notifications) {
      final dateKey =
          "${n.timestamp.year}/${n.timestamp.month.toString().padLeft(2, '0')}/${n.timestamp.day.toString().padLeft(2, '0')}";
      notificationsByDate.putIfAbsent(dateKey, () => []).add(n);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notificationsByDate.keys.length,
      itemBuilder: (context, dateIndex) {
        final date = notificationsByDate.keys.elementAt(dateIndex);
        final notifications = notificationsByDate[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Date Header + Reload hanya di tanggal pertama
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // tampilkan tombol reload hanya sekali di header tanggal pertama
                  if (dateIndex == 0)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      tooltip: "Reload Notifikasi",
                      onPressed: () {
                        if (_selectedDeviceId != null) {
                          _loadNotifications(_selectedDeviceId!.toString());
                        } else {
                          _showErrorSnackBar('Pilih device terlebih dahulu');
                        }
                      },
                    ),
                ],
              ),
            ),

            // 🔹 Notifications for this date
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                // pilih ikon berdasarkan appName
                Widget appIcon;
                final appName = notification.appName.toLowerCase();

                appIcon = FutureBuilder<String?>(
                  future: fetchAppIcon(appName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildIconBox(
                        icon: Icons.notifications,
                        color: Colors.grey.shade300,
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return _buildIconBox(imageUrl: snapshot.data);
                    } else {
                      // fallback ikon default jika gagal fetch
                      return _buildIconBox(
                        icon: Icons.notifications,
                        color: Colors.grey.shade300,
                      );
                    }
                  },
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appIcon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (dateIndex < notificationsByDate.keys.length - 1)
              const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// helper untuk bikin kotak ikon
  Widget _buildIconBox({
    Color? color,
    Gradient? gradient,
    IconData? icon,
    Color iconColor = Colors.white,
    String? imageUrl,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        gradient: gradient,
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            )
          : Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
              0,
              isActive ? -30 : -20, // hanya ikon yang naik
              0,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primary : Colors.transparent,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 4), // jarak konsisten
          Transform.translate(
            offset: const Offset(0, -30),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    final settings = [
      {
        'icon': Icons.family_restroom,
        'title': 'Keluarga',
        'subtitle': 'Lihat kode keluarga Anda',
        'color': const Color(0xFF3B82F6),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Settings Items
          // ...settings.map(
          //   (setting) => _buildSettingItem(
          //     icon: setting['icon'] as IconData,
          //     title: setting['title'] as String,
          //     subtitle: setting['subtitle'] as String,
          //     color: setting['color'] as Color,
          //     onTap: () => _handleSettingTap(setting['title'] as String),
          //   ),
          // ),

          // const SizedBox(height: 24),

          // Divider dengan text
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Akun',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
            ],
          ),

          const SizedBox(height: 16),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),

                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[400]!, Colors.red[600]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSettingTap(String title) async {
    if (title == 'Keluarga') {
      // Show custom loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => const Center(
          child: ParentalControlLoading(
            primaryColor: AppColors.primary,
            type: LoadingType.family,
            // message: "Memuat kode keluarga..",
          ),
        ),
      );

      try {
        final token = _authToken;
        if (token == null) throw Exception('Token tidak tersedia');

        final user = await _authService.getCurrentUser(token);

        if (context.mounted) Navigator.pop(context);

        // if (user?.familyCode != null && user!.familyCode!.isNotEmpty) {
        //   if (context.mounted) {
        //     showDialog(
        //       context: context,
        //       builder: (context) => BarcodeDialog(familyCode: user.familyCode!),
        //     );
        //   }
        // } else {
        //   if (context.mounted) {
        //     _showStyledSnackBar(
        //       'Kode keluarga belum tersedia',
        //       Colors.orange,
        //       Icons.warning_amber_rounded,
        //     );
        //   }
        // }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          _showStyledSnackBar(
            'Gagal memuat kode: ${e.toString().replaceAll('Exception:', '').trim()}',
            Colors.red,
            Icons.error_outline_rounded,
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Konfirmasi Logout",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun?",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _resetFamilyCodeStatus();
        await Provider.of<AuthProvider>(context, listen: false).logout();

        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.register, (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          _showStyledSnackBar(
            'Gagal logout: $e',
            Colors.red,
            Icons.error_outline_rounded,
          );
        }
      }
    }
  }

  Future<void> _resetFamilyCodeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenFamilyCode', false);
      print('✅ Logout - hasSeenFamilyCode diset false');
    } catch (e) {
      print('❌ Error resetting hasSeenFamilyCode: $e');
    }
  }

  void _showStyledSnackBar(
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildActivitiesPage(),
          _buildHomePage(),
          _buildSettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(top: 34), // Tambahkan margin atas
        child: SizedBox(
          height: 110,
          child: AnimatedBuilder(
            animation: _curveAnimation,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 110),
                    painter: BottomNavBackgroundPainter(
                      activeIndex: _curveAnimation.value,
                      totalItems: 3,
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(3, (index) {
                        return _buildNavItem(
                          index == 0
                              ? Icons.notifications
                              : index == 1
                              ? Icons.home
                              : Icons.settings,
                          index == 0
                              ? "Notifikasi"
                              : index == 1
                              ? "Beranda"
                              : "Pengaturan",
                          index,
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
