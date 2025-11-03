import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_navigator.dart';
import 'core/routes/route_generator.dart';
import 'core/routes/app_routes.dart';
import 'modules/auth/src/providers/auth_provider.dart';
import 'modules/auth/src/services/auth_service.dart';
import 'modules/auth/src/storages/secure_storage.dart';
import 'modules/auth/src/services/local_notification_service.dart';
import 'modules/auth/src/services/fcm_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 🔔 Inisialisasi layanan FCM dan notifikasi lokal
  await FCMService().initialize();
  await LocalNotificationService().initialize();

  runApp(const CoupleGuardApp());
}

class CoupleGuardApp extends StatelessWidget {
  const CoupleGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(), SecureStorage()),
        ),
      ],
      child: MaterialApp(
        title: 'Parental Control',
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _loadingRotation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSplashSequence();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: AppConstants.longDuration,
      vsync: this,
    );

    _textController = AnimationController(
      duration: AppConstants.mediumDuration,
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _loadingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );
  }

  Future<void> _startSplashSequence() async {
    try {
      // Start animations
      _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _textController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _loadingController.repeat();

      // Check onboarding status and navigate
      await _checkOnboardingStatus();
    } catch (e) {
      print('❌ Error in splash sequence: $e');
      _navigateToFallback();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
      final hasSeenFamilyCode = prefs.getBool('hasSeenFamilyCode') ?? false;

      print('📢 SplashScreen - hasOnboarded: $hasOnboarded');
      print('📢 SplashScreen - hasSeenFamilyCode: $hasSeenFamilyCode');

      // Tunggu minimal 2 detik total untuk splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigasi berdasarkan status
      if (!hasOnboarded) {
        print('➡️ Navigate to onboarding');
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      } else if (!hasSeenFamilyCode) {
        print('➡️ Navigate to register');
        Navigator.of(context).pushReplacementNamed(AppRoutes.register);
      } else {
        print('➡️ Navigate to family code');
        Navigator.of(context).pushReplacementNamed(AppRoutes.familyCode);
      }
    } catch (e) {
      print('❌ Error checking onboarding status: $e');
      _navigateToFallback();
    }
  }

  void _navigateToFallback() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundDecorations(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppConstants.largePadding,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.family_restroom,
                                size: 60,
                                color: AppColors.primary,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _textOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            Text(
                              AppStrings.appName,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppConstants.appDescription,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w300,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  AnimatedBuilder(
                    animation: _loadingRotation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _loadingRotation.value * 2 * 3.14159,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: 40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
