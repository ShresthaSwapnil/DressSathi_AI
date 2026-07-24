import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _sessionExpired = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get sessionExpired => _sessionExpired;

  AuthProvider() {
    AuthService.onSessionExpired.listen((_) {
      triggerSessionExpired();
    });
  }

  void clearSessionExpired() {
    _sessionExpired = false;
    notifyListeners();
  }

  void triggerSessionExpired() {
    if (_isAuthenticated) {
      _sessionExpired = true;
      logout();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token != null) {
        final userData = await _authService.getUserProfile();
        if (userData != null) {
          _isAuthenticated = true;
          _user = userData;
        } else {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _authService.login(email, password);
      if (res != null) {
        await checkAuthStatus();
        return true;
      }
    } catch (e) {
      debugPrint('login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _authService.register(email, password);
      if (res != null) {
        // auto login after successful registration
        return await login(email, password);
      }
    } catch (e) {
      debugPrint('register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
