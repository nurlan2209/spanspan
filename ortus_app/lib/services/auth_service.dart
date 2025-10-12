import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_data.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    debugPrint('🟢 [AuthService] login вызван');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber, 'password': password}),
      );

      debugPrint('📥 Статус: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveToken(data['token']);
        final user = UserData.fromJson(data['user']);
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': 'Ошибка входа'};
      }
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveToken(data['token']);
        final user = UserData.fromJson(data['user']);
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': 'Ошибка регистрации'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
