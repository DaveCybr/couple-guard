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
  bool _isInitialized = false; // ✅ NEW: Track initialization status

  AuthProvider(this._authService, this._secureStorage) {
    debugPrint('🔵 AuthProvider - Constructor called');
    _initializeAuth();
  }

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // ✅ NEW
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  /// 🔹 Cek apakah user sudah login sebelumnya (token ada di storage)
  Future<void> _initializeAuth() async {
    debugPrint('🔄 AuthProvider - Starting initialization...');
    _setLoading(true);

    try {
      final token = await _secureStorage.getToken();
      debugPrint(
        '🔑 AuthProvider - Token from storage: ${token != null ? "Found (${token.substring(0, 20)}...)" : "Not found"}',
      );

      if (token != null && token.isNotEmpty) {
        _token = token;
        debugPrint('📡 AuthProvider - Fetching user data from API...');

        try {
          final user = await _authService.getCurrentUser(_token!);

          if (user != null) {
            _user = user;
            _status = AuthStatus.authenticated;
            debugPrint('✅ AuthProvider - User authenticated');
            debugPrint('   - Email: ${_user?.email}');
            debugPrint('   - ID: ${_user?.id}');
            debugPrint('   - Family Code: ${_user?.familyCode}');
          } else {
            debugPrint('⚠️ AuthProvider - User data is null, clearing auth');
            await _clearAuth();
          }
        } catch (e) {
          debugPrint('❌ AuthProvider - Error fetching user: $e');
          // Token mungkin expired, clear auth
          await _clearAuth();
        }
      } else {
        debugPrint('ℹ️ AuthProvider - No token found, user not authenticated');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('❌ AuthProvider - Initialization error: $e');
      await _clearAuth();
    } finally {
      _isInitialized = true; // ✅ Mark as initialized
      _setLoading(false);
      debugPrint('✅ AuthProvider - Initialization complete');
      debugPrint('   - Status: $_status');
      debugPrint('   - Token: ${_token != null ? "Present" : "Null"}');
      debugPrint('   - User: ${_user != null ? "Present" : "Null"}');
    }
  }

  /// 🔹 Login via Laravel API
  Future<bool> login(String email, String password) async {
    debugPrint('🔄 AuthProvider - Login attempt for: $email');
    _setLoading(true);

    try {
      final user = await _authService.login(email, password);

      _user = user;
      _token = user.token;

      if (_token != null) {
        await _secureStorage.saveToken(_token!);
        debugPrint('✅ AuthProvider - Token saved to storage');
      }
      await _secureStorage.saveUser(_user!);

      _status = AuthStatus.authenticated;
      _isInitialized = true;

      debugPrint('✅ AuthProvider - Login successful');
      debugPrint('   - User: ${_user?.email}');
      debugPrint('   - ID: ${_user?.id}');
      debugPrint('   - Family Code: ${_user?.familyCode}');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ AuthProvider - Login error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password) async {
    debugPrint('🔄 AuthProvider - Register attempt for: $email');
    _setLoading(true);

    try {
      final user = await _authService.register(
        email: email,
        password: password,
      );

      _user = user;
      _token = user.token;

      if (_token != null) {
        await _secureStorage.saveToken(_token!);
        debugPrint('✅ AuthProvider - Token saved to storage');
      }
      await _secureStorage.saveUser(_user!);

      _status = AuthStatus.authenticated;
      _isInitialized = true;

      debugPrint('✅ AuthProvider - Registration successful');
      debugPrint('   - User: ${_user?.email}');
      debugPrint('   - ID: ${_user?.id}');
      debugPrint('   - Family Code: ${_user?.familyCode}');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ AuthProvider - Register error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    debugPrint('🔄 AuthProvider - Logout initiated');
    _setLoading(true);

    try {
      if (_user?.token != null) {
        debugPrint('📡 AuthProvider - Calling logout API...');
        await _authService.logout(_user!.token!);
        debugPrint('✅ AuthProvider - Logout API success');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider - Logout API error: $e');
    } finally {
      await _clearAuth();
      _setLoading(false);
      debugPrint('✅ AuthProvider - Logout complete');
    }
  }

  Future<void> _clearAuth() async {
    debugPrint('🧹 AuthProvider - Clearing auth data...');
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    await _secureStorage.clearAll();
    debugPrint('✅ AuthProvider - Auth data cleared');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 🔹 Update user di state & storage
  void updateUser(UserModel user) {
    debugPrint('🔄 AuthProvider - Updating user data');
    _user = user;
    _secureStorage.saveUser(user);
    notifyListeners();
    debugPrint('✅ AuthProvider - User data updated');
  }

  /// ✅ NEW: Method untuk refresh user data dari API
  Future<void> refreshUserData() async {
    if (_token == null) {
      debugPrint('⚠️ AuthProvider - Cannot refresh, no token available');
      return;
    }

    debugPrint('🔄 AuthProvider - Refreshing user data...');

    try {
      final user = await _authService.getCurrentUser(_token!);
      if (user != null) {
        _user = user;
        await _secureStorage.saveUser(_user!);
        notifyListeners();
        debugPrint('✅ AuthProvider - User data refreshed');
      } else {
        debugPrint('⚠️ AuthProvider - Refresh returned null user');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider - Refresh error: $e');
    }
  }
}
