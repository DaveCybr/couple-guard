import 'package:couple_guard/modules/auth/src/screens/family_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;

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
  String selectedChild = 'Sarah';
  late AnimationController _animationController;
  late Animation<double> _curveAnimation;

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
                  'Pilih Anak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                ...children.map((child) => _buildChildCard(child)).toList(),
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
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(-6.200000, 106.816666), // Jakarta
                        initialZoom: 14,
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
                              point: LatLng(-6.200000, 106.816666),
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
                    ),
                  ),
                ),
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
                        onTap: () {},
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
                        onTap: () {},
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

  Widget _buildChildCard(Map<String, dynamic> child) {
    final isSelected = selectedChild == child['name'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChild = child['name'];
        });
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
            Text(child['avatar'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        child['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              child['status'] == 'online'
                                  ? Colors.green
                                  : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${child['location']} • Baterai ${child['battery']}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesPage() {
    final notificationsByDate = {
      '2025/08/20': [
        {
          'app': 'King\'s Choice',
          'title': 'King\'s Choice',
          'message':
              'Yang Mulia, acara Perairan Baru dibuka dan telah siap untuk anda bergabung dalam kegembiraan!',
          'time': '12:03',
          'icon': 'game',
          'category': 'Dev',
        },
        {
          'app': 'King\'s Choice',
          'title': 'King\'s Choice',
          'message':
              'Yang Mulia, acara Scarlet Beauty dibuka dan telah siap untuk anda bergabung dalam kegembiraan!',
          'time': '12:03',
          'icon': 'game',
          'category': 'Dev',
        },
        {
          'app': 'Instagram',
          'title': 'farralunee_: -',
          'message': 'ape',
          'time': '12:02',
          'icon': 'instagram',
          'category': 'Dev',
        },
        {
          'app': 'WhatsApp',
          'title': '~ Diva MIF JTI POLIJE NEWW',
          'message': 'Someone shared a message',
          'time': '12:02',
          'icon': 'whatsapp',
          'category': 'Dev',
        },
        {
          'app': 'Shopee',
          'title': 'Shopee',
          'message':
              'Flash Sale dimulai! Dapatkan diskon hingga 90% untuk produk pilihan',
          'time': '11:45',
          'icon': 'shopee',
          'category': 'Dev',
        },
        {
          'app': 'Gmail',
          'title': 'Google Account',
          'message':
              'Sign-in attempt was blocked. We prevented someone from signing in to your account.',
          'time': '11:30',
          'icon': 'gmail',
          'category': 'Dev',
        },
      ],
      '2025/08/19': [
        {
          'app': 'YouTube',
          'title': 'YouTube',
          'message':
              'Kreator favorit Anda baru saja mengupload video baru: "Tutorial Flutter Advanced"',
          'time': '20:15',
          'icon': 'youtube',
          'category': 'Dev',
        },
        {
          'app': 'Telegram',
          'title': 'Flutter Indonesia',
          'message':
              'Ada yang tahu cara fix error ini? RenderFlex overflowed...',
          'time': '19:58',
          'icon': 'telegram',
          'category': 'Dev',
        },
        {
          'app': 'Bank BCA',
          'title': 'BCA mobile',
          'message':
              'Transaksi berhasil. Transfer ke 1234***789 sebesar Rp 50.000',
          'time': '18:30',
          'icon': 'bank',
          'category': 'Dev',
        },
        {
          'app': 'Spotify',
          'title': 'Spotify',
          'message':
              'Discover Weekly Anda sudah siap! Temukan musik baru yang mungkin Anda sukai',
          'time': '17:00',
          'icon': 'spotify',
          'category': 'Dev',
        },
        {
          'app': 'Gojek',
          'title': 'Gojek',
          'message':
              'Promo spesial untuk Anda! Diskon 50% untuk GoFood hingga Rp 25.000',
          'time': '16:45',
          'icon': 'gojek',
          'category': 'Dev',
        },
        {
          'app': 'Facebook',
          'title': 'Facebook',
          'message':
              'John Doe dan 5 teman lainnya memposting sesuatu. Lihat update terbaru mereka.',
          'time': '15:20',
          'icon': 'facebook',
          'category': 'Dev',
        },
      ],
    };

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notificationsByDate.keys.length,
      itemBuilder: (context, dateIndex) {
        final date = notificationsByDate.keys.elementAt(dateIndex);
        final notifications = notificationsByDate[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.zero, // pojok bawah kiri tetap kotak
                    bottomRight: Radius.zero, // pojok bawah kanan tetap kotak
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                    left: BorderSide(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                    right: BorderSide(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                    bottom: BorderSide.none, // bawah tidak ada border
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
            ),

            // Notifications for this date
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final activity = notifications[index];

                // App icon based on type
                Widget appIcon;

                switch (activity['icon']) {
                  case 'game':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.shade100,
                      ),
                      child: Icon(Icons.games, color: Colors.orange, size: 20),
                    );
                    break;
                  case 'instagram':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.pink, Colors.orange],
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'whatsapp':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green,
                      ),
                      child: Icon(Icons.chat, color: Colors.white, size: 20),
                    );
                    break;
                  case 'shopee':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.shade600,
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'gmail':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.shade500,
                      ),
                      child: Icon(Icons.email, color: Colors.white, size: 20),
                    );
                    break;
                  case 'youtube':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.shade600,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'telegram':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.shade500,
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    );
                    break;
                  case 'bank':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.shade700,
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'spotify':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.shade600,
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'gojek':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green.shade700,
                      ),
                      child: Icon(
                        Icons.motorcycle,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  case 'facebook':
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.shade600,
                      ),
                      child: Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                    break;
                  default:
                    appIcon = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade300,
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    );
                }

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
                                  activity['app']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  activity['time']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['title']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['message']!,
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
                              activity['category']!,
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

            // Add spacing after each date section
            if (dateIndex < notificationsByDate.keys.length - 1)
              const SizedBox(height: 16),
          ],
        );
      },
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
        'icon': Icons.person,
        'title': 'Profil Saya',
        'subtitle': 'Kelola profil saya',
      },
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
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final token = authProvider.token;

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
