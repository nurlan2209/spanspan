import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    checkAuth();
  }

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserData? _user;
  bool _isCheckingAuth = false;

  UserData? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isCheckingAuth => _isCheckingAuth;

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final result = await _authService.login(phone, password);
    if (result['success'] == true) {
      _user = result['user'];
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final result = await _authService.register(data);
    if (result['success'] == true) {
      _user = result['user'];
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final profile = await _userService.getUserProfile();
    if (profile != null) {
      _user = profile;
      notifyListeners();
    }
  }

  Future<void> checkAuth() async {
    if (_isCheckingAuth) return;
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token == null) {
        _user = null;
      } else {
        final profile = await _userService.getUserProfile();
        _user = profile;
        if (_user == null) {
          await _authService.logout();
        }
      }
    } catch (_) {
      _user = null;
      await _authService.logout();
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }
}
