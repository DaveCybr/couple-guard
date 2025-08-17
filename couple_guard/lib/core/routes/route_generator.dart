import 'package:couple_guard/core/routes/app_routes.dart';
import 'package:couple_guard/modules/auth/src/screens/login_screen.dart';
import 'package:couple_guard/onboarding_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

import 'page_transitions.dart';
import 'route_middleware.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      // Onboarding routes
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return RouteMiddleware.guestOnly(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          ),
        );

      // case '/auth/register':
      //   return RouteMiddleware.guestOnly(
      //     MaterialPageRoute(
      //       builder: (_) => const RegisterPage(),
      //       settings: settings,
      //     ),
      //   );

      // case '/auth/forgot-password':
      //   return RouteMiddleware.guestOnly(
      //     MaterialPageRoute(
      //       builder: (_) => const ForgotPasswordPage(),
      //       settings: settings,
      //     ),
      //   );

      // // Protected routes (require auth)
      // case '/dashboard':
      // case '/home':
      //   return RouteMiddleware.requireAuth(
      //     MaterialPageRoute(
      //       builder: (_) => const DashboardPage(),
      //       settings: settings,
      //     ),
      //   );

      // case '/location':
      //   return RouteMiddleware.requireAuth(
      //     MaterialPageRoute(
      //       builder: (_) => const LocationTrackingPage(),
      //       settings: settings,
      //     ),
      //   );

      // case '/monitoring':
      //   return RouteMiddleware.requireAuth(
      //     MaterialPageRoute(
      //       builder: (_) => const MonitoringDashboardPage(),
      //       settings: settings,
      //     ),
      //   );
      // Error handling
      default:
        return PageTransitions.slideFromRight(
          ErrorPage(routeName: settings.name) as Widget,
          settings,
        );
    }
  }
}

class ErrorPage extends StatelessWidget {
  final String? routeName;

  const ErrorPage({Key? key, this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error: Route "${routeName ?? "unknown"}" not found'),
      ),
    );
  }
}
