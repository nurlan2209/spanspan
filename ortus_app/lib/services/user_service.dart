import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  Future<UserModel?> getProfile() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.usersUrl}/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await AuthService().getToken();
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
