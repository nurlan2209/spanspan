import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await _saveToken(data['token']);
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {
        'success': false,
        'message': json.decode(response.body)['message'],
      };
    }
  }

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveToken(data['token']);
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {
        'success': false,
        'message': json.decode(response.body)['message'],
      };
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
