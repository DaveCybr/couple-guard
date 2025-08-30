// lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../storages/secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  late GoogleSignIn _googleSignIn;

  AuthProvider(this._authService, this._secureStorage) {
    _initializeAuth();
    _initializeGoogleSignIn();
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
  String generateParentCode([int length = 6]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

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

  Future<void> _initializeGoogleSignIn() async {
    try {
      _googleSignIn = GoogleSignIn.instance;
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint('Google Sign In initialization error: $e');
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      // Authenticate dengan Google
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception("Login dengan Google dibatalkan");
      }
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Buat credential untuk Firebase (versi sederhana)
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Cek apakah user sudah ada di Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

        Map<String, dynamic> userData;

        if (userDoc.exists) {
          // User sudah ada
          userData = userDoc.data() as Map<String, dynamic>;
        } else {
          // User baru, buat data baru
          String parentCode = generateParentCode();
          userData = {
            'uid': firebaseUser.uid,
            'name':
                googleUser.displayName ?? firebaseUser.displayName ?? 'User',
            'email': googleUser.email,
            'parentCode': parentCode,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Simpan ke Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set(userData);
        }

        // Mapping ke UserModel
        _user = UserModel(
          id: 0,
          name: userData['name'] ?? googleUser.displayName ?? 'User',
          email: userData['email'] ?? googleUser.email,
          phone: firebaseUser.phoneNumber,
          avatar: googleUser.photoUrl ?? firebaseUser.photoURL,
          isEmailVerified: firebaseUser.emailVerified,
          partnerId: userData['partnerId'],
          partnerName: userData['partnerName'],
          parentCode: userData['parentCode'],
          createdAt:
              userData['createdAt'] != null
                  ? (userData['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
          updatedAt:
              userData['updatedAt'] != null
                  ? (userData['updatedAt'] as Timestamp).toDate()
                  : DateTime.now(),
        );

        // Get Firebase token
        _token = await firebaseUser.getIdToken();

        // Simpan ke storage lokal
        await _secureStorage.saveToken(_token!);
        await _secureStorage.saveUser(_user!);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } on GoogleSignInException catch (e) {
      debugPrint("Google Sign In Exception: ${e.code} - ${e.description}");
      throw Exception("Google Sign In gagal: ${e.description}");
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
      throw Exception("Firebase Auth gagal: ${e.message}");
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      throw Exception("Terjadi kesalahan: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // 🔥 ambil data user dari Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          _user = UserModel(
            id: 0,
            name: data['name'],
            email: data['email'],
            phone: user.phoneNumber,
            avatar: user.photoURL,
            isEmailVerified: user.emailVerified,
            partnerId: data['partnerId'] ?? null,
            partnerName: data['partnerName'] ?? null,
            parentCode: data['parentCode'],
            createdAt:
                (data['createdAt'] != null)
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
            updatedAt:
                (data['updatedAt'] != null)
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : DateTime.now(),
          );

          _token = await user.getIdToken();

          // simpan ke storage lokal
          await _secureStorage.saveToken(_token!);
          await _secureStorage.saveUser(_user!);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
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
        String parentCode = generateParentCode();

        // simpan ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'parentCode': parentCode,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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
          parentCode: parentCode,
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
      // 1. Sign out dari Firebase (WAJIB untuk kedua jenis login)
      await FirebaseAuth.instance.signOut();

      // 2. Sign out dari Google (OPSIONAL, hanya untuk Google Sign-In)
      // Ini untuk memastikan user harus pilih akun Google lagi next time
      try {
        if (_googleSignIn != null) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        // Ignore error jika Google Sign In tidak diinisialisasi
        debugPrint('Google sign out error (ignored): $e');
      }

      // 3. Clear local storage dan state (WAJIB untuk semua)
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
