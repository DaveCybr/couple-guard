// core/navigation/app_navigator.dart - FIXED VERSION (Simplified)
import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get _navigator => navigatorKey.currentState;
  static BuildContext? get context => _navigator?.context;

  // Base navigation methods
  static Future<T?> push<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return _navigator!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return _navigator!.pop<T>(result);
  }

  static void popUntil(String routeName) {
    return _navigator!.popUntil(ModalRoute.withName(routeName));
  }

  static bool canPop() {
    return _navigator!.canPop();
  }

  // Utility methods
  static String? getCurrentRoute() {
    String? currentRoute;
    _navigator!.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }

  static bool isCurrentRoute(String routeName) {
    return getCurrentRoute() == routeName;
  }

  // Snackbar helper
  static void showSnackBar({
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context!);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
