// core/navigation/route_middleware.dart - FIXED VERSION (No Email Verification)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../modules/auth/src/providers/auth_provider.dart';

class RouteMiddleware {
  // Middleware untuk routes yang memerlukan authentication SAJA
  static PageRoute<T> requireAuth<T extends Object?>(PageRoute<T> route) {
    return _AuthRequiredRoute<T>(route);
  }

  // Middleware untuk routes yang hanya bisa diakses guest (tidak authenticated)
  static PageRoute<T> guestOnly<T extends Object?>(PageRoute<T> route) {
    return _GuestOnlyRoute<T>(route);
  }
}

// Route yang memerlukan authentication saja (TANPA email verification)
class _AuthRequiredRoute<T> extends PageRoute<T> {
  final PageRoute<T> _route;

  _AuthRequiredRoute(this._route);

  @override
  Color? get barrierColor => _route.barrierColor;

  @override
  String? get barrierLabel => _route.barrierLabel;

  @override
  bool get maintainState => _route.maintainState ?? true;

  @override
  Duration get transitionDuration =>
      _route.transitionDuration ?? const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration =>
      _route.reverseTransitionDuration ?? const Duration(milliseconds: 300);

  @override
  RouteSettings get settings => _route.settings;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // FIXED: Fallback ke default transition jika _route.buildTransitions null
    try {
      return _route.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    } catch (e) {
      // Fallback ke slide transition default
      return SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.ease)),
        ),
        child: child,
      );
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // HANYA cek authenticated, TIDAK cek email verification
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pushReplacementNamed('/auth/login');
            } else {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth/login', (route) => false);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika authenticated, langsung tampilkan halaman
        return _route.buildPage(context, animation, secondaryAnimation);
      },
    );
  }
}

// Guest only route - redirect ke home jika sudah authenticated
class _GuestOnlyRoute<T> extends PageRoute<T> {
  final PageRoute<T> _route;

  _GuestOnlyRoute(this._route);

  @override
  Color? get barrierColor => _route.barrierColor;

  @override
  String? get barrierLabel => _route.barrierLabel;

  @override
  bool get maintainState => _route.maintainState ?? true;

  @override
  Duration get transitionDuration =>
      _route.transitionDuration ?? const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration =>
      _route.reverseTransitionDuration ?? const Duration(milliseconds: 300);

  @override
  RouteSettings get settings => _route.settings;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // FIXED: Fallback ke default transition jika _route.buildTransitions null
    try {
      return _route.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    } catch (e) {
      // Fallback ke slide transition default
      return SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.ease)),
        ),
        child: child,
      );
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah authenticated, redirect ke home
        if (authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika belum authenticated, tampilkan halaman guest
        return _route.buildPage(context, animation, secondaryAnimation);
      },
    );
  }
}
