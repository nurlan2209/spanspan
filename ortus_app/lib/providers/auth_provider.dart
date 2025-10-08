import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<bool> register(Map<String, dynamic> userData) async {
    final result = await _authService.register(userData);
    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String phoneNumber, String password) async {
    final result = await _authService.login(phoneNumber, password);
    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final updatedUser = await _userService.getProfile();
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
    }
  }
}
