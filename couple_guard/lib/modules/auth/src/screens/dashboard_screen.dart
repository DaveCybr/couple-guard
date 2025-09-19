import 'package:couple_guard/modules/auth/src/screens/album_camera_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/camera_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/family_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/loading_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import 'dart:ui' as ui;
import '../services/family_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './realtime_location.dart';

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
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(auth.user?.name ?? "User")}&background=random&color=fff&size=128',
                                ),
                                onBackgroundImageError: (
                                  exception,
                                  stackTrace,
                                ) {
                                  // Handle error jika gagal load image
                                },
                                child:
                                    auth.user?.name == null
                                        ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    auth.user?.name ?? "User Name",
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
                      Container(
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
    final bgPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.25) // warna shadow
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

  final NotificationService _notificationService = NotificationService();
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

  Future<void> _loadNotifications(int childId) async {
    if (_authToken == null) {
      debugPrint("❌ Tidak ada auth token, skip load notifications");
      return;
    }

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final result = await _notificationService.fetchNotifications(
        authToken: _authToken!, // pakai token dari AuthProvider
        childId: childId,
        page: 1,
        limit: 50,
      );

      setState(() {
        _notifications = result['notifications'] as List<NotificationModel>;
        _pagination = result['pagination'];
        _summary = result['summary'];
      });

      debugPrint(
        "✅ Berhasil load ${_notifications.length} notifikasi untuk child $childId",
      );
    } catch (e) {
      debugPrint("❌ Error load notifications: $e");
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
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
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _curveAnimation = Tween<double>(
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

    _curveAnimation = Tween<double>(
      begin: oldIndex.toDouble(),
      end: newIndex.toDouble(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0);
  }

  final List<Map<String, dynamic>> children = [
    {
      'name': 'Sarah',
      'age': 12,
      'avatar': '👧',
      'status': 'online',
      'location': 'Sekolah',
      'battery': 85,
    },
    {
      'name': 'Alex',
      'age': 8,
      'avatar': '👦',
      'status': 'offline',
      'location': 'Rumah',
      'battery': 45,
    },
  ];

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Family',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: ParentalControlLoading(
          primaryColor: AppColors.primary,
          type: LoadingType.family,
          message: "Memuat data..",
        ),)
                else if (_families.isEmpty)
                  const Text("Tidak ada family")
                else if (_families.length <= 3)
                  // tampilkan langsung tanpa scrollbar & tanpa padding kanan
                  Column(
                    children:
                        _families
                            .map((family) => _buildFamilyCard(family))
                            .toList(),
                  )
                else
                  SizedBox(
                    height: 200, // cukup untuk ±3 item
                    child: Scrollbar(
                      thumbVisibility: true, // selalu tampil
                      radius: const Radius.circular(8),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(
                          right: 8, // kasih jarak biar gak nabrak scrollbar
                        ),
                        itemCount: _families.length,
                        itemBuilder: (context, index) {
                          final family = _families[index];
                          return _buildFamilyCard(family);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Lokasi dengan Map
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),

                // Map view pakai flutter_map
                if (_authToken != null && selectedChild != null)
                  RealtimeMapWidget(
                    key: ValueKey(
                      selectedChild,
                    ), // reset state kalau ganti child
                    familyId: selectedChild!,
                    authToken: _authToken!,
                  )
                else
                  _buildEmptyMapWidget(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text("Geofence"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text("Pembaruan"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Potretan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potretan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (selectedChild != null && _authToken != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AlbumCameraScreen(
                                      selectedChildId:
                                          selectedChild!, // ✅ id anak
                                      jwtToken: _authToken!, // ✅ token
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pilih family dulu sebelum membuka kamera",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Column(
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text("Potretan Kamera"),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: const [
                            Icon(
                              Icons.phone_android,
                              color: Colors.green,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text("Potretan Layar"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Kamera & Layar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kamera & Layar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (selectedChild != null && _authToken != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CameraScreen(
                                      selectedChildId:
                                          selectedChild!, // ✅ id anak
                                      jwtToken: _authToken!, // ✅ token
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pilih family dulu sebelum membuka kamera",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Column(
                          children: const [
                            Icon(
                              Icons.videocam,
                              color: Colors.purple,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text("Kamera"),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: const [
                            Icon(
                              Icons.desktop_windows,
                              color: Colors.orange,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text("Layar"),
                          ],
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

  Widget _buildFamilyCard(GetFamily family) {
    final isSelected = selectedChild == family.id; // bandingkan dengan ID
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChild = family.id; // simpan id
        });
        _loadNotifications(family.id); // load notifications untuk child ini
        debugPrint("👀 Sedang mengamati family ${family.id}");
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF4FF) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.family_restroom, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                family.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesPage() {
    // Group notifications by date (yyyy/MM/dd)
    final Map<String, List<NotificationModel>> notificationsByDate = {};
    for (var n in _notifications) {
      final dateKey =
          "${n.timestamp.year}/${n.timestamp.month.toString().padLeft(2, '0')}/${n.timestamp.day.toString().padLeft(2, '0')}";
      notificationsByDate.putIfAbsent(dateKey, () => []).add(n);
    }

    if (_isLoadingNotifications) {
      return const Center(
        child: ParentalControlLoading(
          primaryColor: AppColors.primary,
          type: LoadingType.family,
          message: "Memuat data..",
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text("Belum ada notifikasi"));
    }

    if (selectedChild == null) {
      return const Center(
        child: Text("Pilih family dulu untuk melihat notifikasi"),
      );
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
                      tooltip: "Reload",
                      onPressed: () {
                        _loadNotifications(selectedChild!); // fungsi refresh
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
                final activity = notifications[index];

                // pilih ikon berdasarkan appPackage
                Widget appIcon;
                final pkg = activity.appPackage?.toLowerCase() ?? '';

                appIcon = FutureBuilder<String?>(
                  future: fetchAppIcon(pkg),
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
                                Text(
                                  activity.title ?? "-",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.content ?? "",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.category ?? "",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
    String? imageUrl, // tambahkan
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        gradient: gradient,
      ),
      child:
          imageUrl != null
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
                boxShadow:
                    isActive
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
        'subtitle': 'Kelola keluarga',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: settings.length + 1, // +1 untuk Logout
      itemBuilder: (context, index) {
        if (index < settings.length) {
          final setting = settings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (setting['title'] == 'Kode'
                          ? Colors.green
                          : const Color(0xFF3B82F6))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  setting['icon'] as IconData,
                  color:
                      (setting['title'] == 'Kode'
                          ? Colors.green
                          : const Color(0xFF3B82F6)),
                  size: 20,
                ),
              ),
              title: Text(
                setting['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color:
                      setting['title'] == 'Kode' ? Colors.green : Colors.black,
                ),
              ),
              subtitle: Text(
                setting['subtitle'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                if (setting['title'] == 'Keluarga') {
                  final token = _authToken;

                  if (token != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyScreen(authToken: token),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Token tidak tersedia, silakan login ulang',
                        ),
                      ),
                    );
                  }
                } else if (setting['title'] == 'Kode') {
                  // 🔹 tampilkan kode unik di popup
                  showDialog(
                    context: context,
                    builder: (context) {
                      // misal kode tersimpan di _user.parentCode
                      String code = "Belum tersedia";

                      return AlertDialog(
                        title: const Text('Kode Unik'),
                        content: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${setting['title']} diklik')),
                  );
                }
              },
            ),
          );
        } else {
          // 🔹 Logout
          return Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: const Text("Apakah Anda yakin ingin logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Logout"),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  try {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout(); // ✅ tidak pakai argumen

                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal logout: $e')),
                      );
                    }
                  }
                }
              },
            ),
          );
        }
      },
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
