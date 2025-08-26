// lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../storages/secure_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Login ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Buat UserModel dari Firebase user
        _user = UserModel(
          id: firebaseUser.uid.hashCode, // karena di Firebase ga ada int id
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber,
          avatar: firebaseUser.photoURL,
          isEmailVerified: firebaseUser.emailVerified,
          partnerId: null,
          partnerName: null,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
        );

        _token = await firebaseUser.getIdToken();
        _status = AuthStatus.authenticated;

        // simpan ke storage lokal
        await _secureStorage.saveToken(_token!);
        await _secureStorage.saveUser(_user!);

        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint("🔥 FirebaseAuthException: ${e.code} | ${e.message}");
      if (e.code == 'user-not-found') {
        throw ('User tidak ditemukan');
      } else if (e.code == 'wrong-password') {
        throw ('Password salah');
      } else if (e.code == 'invalid-email') {
        throw ('Format email tidak valid');
      } else {
        throw ('Error Firebase: ${e.code} - ${e.message}');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      // register ke firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // update displayName biar nama tersimpan di firebase
        await user.updateDisplayName(name);
        await user.reload();

        // mapping Firebase User -> UserModel
        _user = UserModel(
          id: 0, // karena Firebase tidak pakai integer ID, bisa isi default
          name: user.displayName ?? name,
          email: user.email ?? email,
          phone: user.phoneNumber,
          avatar: user.photoURL,
          isEmailVerified: user.emailVerified,
          partnerId: null,
          partnerName: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _token = await user.getIdToken();

        // simpan ke storage lokal
        await _secureStorage.saveToken(_token!);
        await _secureStorage.saveUser(_user!);

        notifyListeners();
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuth Error: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      print("Unexpected Error: $e");
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
