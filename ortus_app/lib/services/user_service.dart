import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_data.dart';
import 'auth_service.dart';

class UserService {
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

  Future<List<UserData>> getStaff({String? role, String? status}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final params = <String, String>{};
    if (role != null && role.isNotEmpty) params['role'] = role;
    if (status != null && status.isNotEmpty) params['status'] = status;

    var url = '${ApiConfig.usersUrl}/staff';
    if (params.isNotEmpty) {
      final query =
          params.entries.map((e) => '${e.key}=${e.value}').join('&');
      url += '?$query';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => UserData.fromJson(e)).toList();
    }
    return [];
  }

  Future<UserData?> createStaff({
    required String phoneNumber,
    required String fullName,
    required String password,
    required String role,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.usersUrl}/staff'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'phoneNumber': phoneNumber,
        'fullName': fullName,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return UserData.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<UserData?> updateStaffStatus({
    required String userId,
    required String status,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.usersUrl}/staff/$userId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return UserData.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> deleteStaff(String userId) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${ApiConfig.usersUrl}/staff/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
