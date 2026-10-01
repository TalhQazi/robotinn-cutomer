import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getData(AppConstants.authToken);
      if (token != null) {
        final profile = await ApiService.getMe();
        if (profile != null && !profile.isBanned && profile.type == 'customer') {
          _user = profile;
        } else {
          await ApiService.logout();
          _user = null;
        }
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await ApiService.login(email, password);
      _user = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await ApiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      _user = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await ApiService.signInWithGoogle();
      _user = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  String _formatErrorMessage(String raw) {
    if (raw.contains('BANNED:')) {
      return raw.replaceAll('Exception: BANNED:', '').replaceAll('BANNED:', '').trim();
    }
    if (raw.contains('invalid-credential') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    if (raw.contains('10:') || raw.contains('sign_in_failed')) {
      return 'Google Sign-In configuration error (Developer Error 10). The SHA-1 fingerprint must be added to Firebase Console.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }
}
