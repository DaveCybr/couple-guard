// lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../storages/secure_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  AuthProvider(this._authService, this._secureStorage) {
    _initializeAuth();
  }

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;
  bool get hasPartner => _user?.partnerId != null;

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final token = await _secureStorage.getToken();
      if (token != null) {
        _token = token;
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _user = user;
          _status = AuthStatus.authenticated;
        } else {
          await _clearAuth();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _clearAuth();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final authResult = await _authService.login(email, password);
      if (authResult.success) {
        _token = authResult.token;
        _user = authResult.user;
        _status = AuthStatus.authenticated;
        await _secureStorage.saveToken(authResult.token!);
        await _secureStorage.saveUser(authResult.user!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.register(name, email, password);
      return result.success;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      await _clearAuth();
    } catch (e) {
      debugPrint('Logout error: $e');
      await _clearAuth();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    await _secureStorage.clearAll();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _user = user;
    _secureStorage.saveUser(user);
    notifyListeners();
  }
}
