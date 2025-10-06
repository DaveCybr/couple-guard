import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../src/services/pair_service.dart';

class FamilyCodeScreen extends StatefulWidget {
  const FamilyCodeScreen({Key? key}) : super(key: key);

  @override
  State<FamilyCodeScreen> createState() => _FamilyCodeScreenState();
}

class _FamilyCodeScreenState extends State<FamilyCodeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isDevicePaired = false;
  String? _pairedDeviceName;
  bool _isLoading = true;

  String? _familyCode; // ✅ Simpan kode keluarga di sini

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _markFamilyCodeAsSeen();

    // ✅ Ambil familyCode setelah widget dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _familyCode = authProvider.user?.familyCode;
      _initializePusher(); // Pindahkan ke sini agar _familyCode sudah tersedia
    });
  }

  Future<void> _markFamilyCodeAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenFamilyCode', true);
      print('✅ FamilyCodeScreen - hasSeenFamilyCode diset true');
    } catch (e) {
      print('❌ Error saving hasSeenFamilyCode: $e');
    }
  }

  Future<void> _initializePusher() async {
    try {
      await PusherService.initialize();
      await Future.delayed(const Duration(seconds: 1));

      if (_familyCode != null && _familyCode!.isNotEmpty) {
        print('🚀 Subscribing to Pusher channel for family: $_familyCode');

        await PusherService.subscribeToFamilyChannel(
          _familyCode!,
          _handleDevicePaired,
        );
      } else {
        print('❌ Family code is null or empty');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error initializing Pusher: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleDevicePaired(PusherEvent event) {
    print('🎯 Device paired event received: ${event.data}');

    try {
      final Map<String, dynamic> data = json.decode(event.data!);
      final deviceName = data['device_name'] ?? 'Unknown Device';

      if (mounted) {
        setState(() {
          _isDevicePaired = true;
          _pairedDeviceName = deviceName;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deviceName berhasil terhubung!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            print('➡️ Navigating to dashboard after pairing');
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
          }
        });
      }
    } catch (e) {
      print('❌ Error handling device paired event: $e');
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    // ✅ Jangan pakai Provider.of di sini
    if (_familyCode != null) {
      PusherService.unsubscribeFromFamilyChannel(_familyCode!);
      print('🧹 Unsubscribed from Pusher channel: $_familyCode');
    }

    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kode berhasil disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final familyCode =
        _familyCode ?? authProvider.user?.familyCode ?? 'LOADING...';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  if (_isLoading)
                    _buildLoadingIndicator()
                  else
                    Column(
                      children: [
                        _buildFamilyCodeCard(familyCode),
                        const SizedBox(height: 24),
                        _buildInfoBox(),
                        if (_isDevicePaired) _buildPairingSuccess(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.family_restroom,
            size: 50,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Selamat Datang!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ini adalah kode keluarga Anda',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Menyiapkan koneksi real-time...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCodeCard(String familyCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Kode Keluarga',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan kode ini untuk mengundang anggota keluarga',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (familyCode != 'LOADING...')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: familyCode,
                width: 250,
                height: 250,
                drawText: false,
                backgroundColor: AppColors.background,
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  familyCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _copyToClipboard(context, familyCode),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 24, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pairing',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aplikasi sedang menunggu device lain melakukan pairing. '
                  'Scan QR code atau masukkan kode di device lain untuk melanjutkan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingSuccess() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pairing Berhasil!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_pairedDeviceName != null)
                  Text(
                    'Device "$_pairedDeviceName" berhasil terhubung',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                Text(
                  'Mengarahkan ke dashboard...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }
}
