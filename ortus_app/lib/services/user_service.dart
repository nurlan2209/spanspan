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

  Future<void> createUser({
    required String phoneNumber,
    required String iin,
    required String fullName,
    required DateTime dateOfBirth,
    required double weight,
    required String userType,
    required String password,
  }) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/create-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'phoneNumber': phoneNumber,
        'iin': iin,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'weight': weight,
        'userType': userType,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user');
    }
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
