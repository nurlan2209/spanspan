import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserData? _user;

  UserData? get user => _user;
  bool get isAuthenticated => _user != null;

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

  Future<void> refreshUser() async {}
  Future<void> checkAuth() async {}
}
