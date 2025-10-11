import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart'; // <-- Добавлен импорт
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _errorMessage = null;
    final result = await _authService.register(userData);
    if (result['success']) {
      _user = result['user'];
      _token = await _authService.getToken();
      notifyListeners();
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    _errorMessage = null;
    final result = await _authService.login(phoneNumber, password);
    if (result['success']) {
      _user = result['user'];
      _token = await _authService.getToken();
      notifyListeners();
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result;
  }

  // --- НОВЫЙ МЕТОД ---
  // Обновляет данные текущего пользователя с сервера
  Future<void> refreshUser() async {
    try {
      final updatedUser = await UserService().getUserProfile();
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      print("Ошибка при обновлении пользователя: $e");
      // Можно обработать ошибку, если нужно
    }
  }
  // --- КОНЕЦ НОВОГО МЕТОДА ---

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _authService.logout();
    notifyListeners();
  }
}
