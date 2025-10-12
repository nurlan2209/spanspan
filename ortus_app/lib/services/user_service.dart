import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_data.dart'; 
import 'auth_service.dart';

class UserService {
  // ИСПРАВЛЕНО: Переименован метод для соответствия вызову
  Future<UserData?> getUserProfile() async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.usersUrl}/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserData.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${ApiConfig.usersUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    return response.statusCode == 200;
  }
}
