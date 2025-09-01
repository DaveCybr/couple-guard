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

  /// 🔹 Cek apakah user sudah login sebelumnya (token ada di storage)
  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final token = await _secureStorage.getToken();
      if (token != null) {
        _token = token;
        final user = await _authService.getCurrentUser(_token!);
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

  /// 🔹 Login via Laravel API
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.login(email, password);

      _user = user;

      // kalau API mengembalikan token, simpan juga
      // misal token ada di response auth, tambahkan return di AuthService.login
      // sementara ini pakai null-check
      if (_token != null) {
        await _secureStorage.saveToken(_token!);
      }

      await _secureStorage.saveUser(_user!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String role, {
    String? phone,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );

      _user = user;

      await _secureStorage.saveUser(_user!);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Register error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Logout (hapus token di server + clear storage)
  Future<void> logout() async {
    _setLoading(true);
    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      await _clearAuth();
      _setLoading(false);
    }
  }

  /// 🔹 Bersihkan state auth & storage
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

  /// 🔹 Update user di state & storage
  void updateUser(UserModel user) {
    _user = user;
    _secureStorage.saveUser(user);
    notifyListeners();
  }
}
