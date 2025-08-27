import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class BottomNavBackgroundPainter extends CustomPainter {
  final double activeIndex;
  final int totalItems;

  BottomNavBackgroundPainter({required this.activeIndex, this.totalItems = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final path = Path();

    final double itemWidth = size.width / totalItems;
    final double centerX = itemWidth * activeIndex + itemWidth / 2;
    final double curveRadius = 33;
    final double curveHeight = 33;

    path.lineTo(centerX - curveRadius * 2, 0);

    // Melengkung ke atas (semakin besar curveHeight, makin tinggi)
    path.cubicTo(
      centerX - curveRadius,
      0, // kontrol kiri 1
      centerX - curveRadius,
      -curveHeight, // kontrol kiri 2
      centerX,
      -curveHeight, // titik puncak
    );

    path.cubicTo(
      centerX + curveRadius,
      -curveHeight, // kontrol kanan 1
      centerX + curveRadius,
      0, // kontrol kanan 2
      centerX + curveRadius * 2,
      0, // titik akhir
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BottomNavBackgroundPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex;
  }
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
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

  final List<Map<String, dynamic>> quickActions = [
    {'icon': Icons.location_on, 'label': 'Lokasi', 'color': Colors.blue},
    {'icon': Icons.camera_alt, 'label': 'Kamera', 'color': Colors.green},
    {'icon': Icons.screen_share, 'label': 'Mirror', 'color': Colors.purple},
    {'icon': Icons.block, 'label': 'Blokir', 'color': Colors.red},
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
              borderRadius: BorderRadius.circular(12),
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

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  'Aksi Cepat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: quickActions.length,
                  itemBuilder: (context, index) {
                    final action = quickActions[index];
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${action['label']} diklik')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              action['color'].withOpacity(0.1),
                              action['color'].withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: action['color'].withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: action['color'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                action['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action['label'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
    final activities = [
      {
        'time': '14:30',
        'activity': 'Sarah membuka Instagram',
        'status': 'allowed',
      },
      {
        'time': '14:15',
        'activity': 'Lokasi berubah ke Taman',
        'status': 'normal',
      },
      {'time': '13:45', 'activity': 'Screen time 2 jam', 'status': 'warning'},
      {
        'time': '13:20',
        'activity': 'Alex coba buka YouTube',
        'status': 'blocked',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        Color statusColor =
            activity['status'] == 'blocked'
                ? Colors.red
                : activity['status'] == 'warning'
                ? Colors.orange
                : activity['status'] == 'allowed'
                ? Colors.green
                : Colors.blue;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.circle, color: statusColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['activity']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      activity['time']!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        'title': 'Profil Anak',
        'subtitle': 'Kelola profil anak',
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifikasi',
        'subtitle': 'Pengaturan notifikasi',
      },
      {
        'icon': Icons.security,
        'title': 'Keamanan',
        'subtitle': 'Pengaturan keamanan',
      },
      {'icon': Icons.help, 'title': 'Bantuan', 'subtitle': 'FAQ dan support'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: settings.length,
      itemBuilder: (context, index) {
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
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                setting['icon'] as IconData,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            title: Text(
              setting['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting['title']} diklik')),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Couple Guard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildActivitiesPage(),
          _buildHomePage(),
          _buildSettingsPage(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 110,
        child: AnimatedBuilder(
          animation: _curveAnimation,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 90),
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
                            ? Icons.smartphone
                            : Icons.person,
                        index == 0
                            ? "Notifikasi"
                            : index == 1
                            ? "Beranda"
                            : "Saya",
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
    );
  }
}
