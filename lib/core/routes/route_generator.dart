// core/routes/route_generator.dart
import 'package:couple_guard/modules/auth/src/screens/dashboard_screen.dart';
import 'package:couple_guard/modules/auth/src/screens/family_screen.dart';
import 'package:flutter/material.dart';
import './app_routes.dart';
import 'package:couple_guard/onboarding_screen.dart';
import '../../modules/auth/src/screens/login_screen.dart';
import '../../modules/auth/src/screens/register_screen.dart';
import '../../modules/auth/src/screens/geofence_detail_screen.dart';
import '/main.dart'; // Import main.dart untuk mengakses SplashScreen

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';
    final dynamic args = settings.arguments;

    print('🛣️ RouteGenerator: Navigating to $routeName');

    switch (routeName) {
      // Splash & Onboarding
      case '/':
        print('➡️ Creating SplashScreen');
        return _createRoute(const SplashScreen(), settings);

      case AppRoutes.onboarding:
        print('➡️ Creating OnboardingScreen');
        return _createRoute(const OnboardingScreen(), settings);

      // Auth Routes
      case AppRoutes.login:
        print('➡️ Creating LoginScreen');
        return _createRoute(const LoginScreen(), settings);

      case AppRoutes.register:
        print('➡️ Creating RegisterScreen');
        return _createRoute(const RegisterScreen(), settings);

      case AppRoutes.familyCode:
        print('➡️ Creating FamilyCodeScreen');
        return _createRoute(const FamilyCodeScreen(), settings);

      case AppRoutes.geofenceDetail:
        print('➡️ Creating GeofenceDetailScreen');
        if (args != null && args is Map<String, dynamic>) {
          return _createRoute(GeofenceDetailScreen(arguments: args), settings);
        } else {
          print('❌ GeofenceDetail: Invalid arguments');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('Error: Invalid geofence data')),
            ),
            settings,
          );
        }

      case AppRoutes.forgotPassword:
        return _createRoute(
          const Scaffold(
            body: Center(
              child: Text('Forgot Password Screen - Under Development'),
            ),
          ),
          settings,
        );

      // Main Routes
      case AppRoutes.dashboard:
        print('➡️ Creating DashboardScreen');
        return _createRoute(const DashboardScreen(), settings);

      case AppRoutes.profile:
        return _createRoute(
          const Scaffold(
            body: Center(child: Text('Profile Screen - Under Development')),
          ),
          settings,
        );

      // Default/Error Route
      default:
        print('❌ Route not found: $routeName');
        return _createRoute(_buildErrorPage(routeName), settings);
    }
  }

  static PageRouteBuilder<dynamic> _createRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Widget _buildErrorPage(String routeName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Route "$routeName" not found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
