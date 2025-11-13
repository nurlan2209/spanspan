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

  Future<List<UserData>> getPendingStudents({String? period}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    String url = '${ApiConfig.baseUrl}/users/pending';
    if (period != null && period.isNotEmpty) {
      url += '?period=$period';
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

  Future<UserData?> assignStudentToGroup({
    required String studentId,
    required String groupId,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/$studentId/assign-group'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'groupId': groupId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['student'] != null) {
        return UserData.fromJson(data['student']);
      }
    }
    return null;
  }

  Future<List<UserData>> getStudents({
    String? search,
    String? status,
    String? groupId,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (groupId != null && groupId.isNotEmpty) params['groupId'] = groupId;

    var url = '${ApiConfig.baseUrl}/users/students';
    if (params.isNotEmpty) {
      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
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

  Future<List<UserData>> getStaff({
    String? role,
    String? search,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final params = <String, String>{};
    if (role != null && role.isNotEmpty && role != 'all') {
      params['role'] = role;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    var url = '${ApiConfig.baseUrl}/users/staff';
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

  Future<UserData?> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId/status'),
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

  Future<bool> exportStudents({
    String? status,
    String? groupId,
    String? search,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final params = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (groupId != null && groupId.isNotEmpty) {
      params['groupId'] = groupId;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    var url = '${ApiConfig.baseUrl}/export/students?format=csv';
    if (params.isNotEmpty) {
      final query =
          params.entries.map((e) => '${e.key}=${e.value}').join('&');
      url += '&$query';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<void> createStudentByManager({
    required String role,
    required String phoneNumber,
    required String iin,
    required String fullName,
    required String password,
    required DateTime dateOfBirth,
    String? groupId,
  }) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/create-student'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'phoneNumber': phoneNumber,
        'iin': iin,
        'fullName': fullName,
        'password': password,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'userType': role,
        'groupId': groupId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(json.decode(response.body)['message'] ??
          'Failed to create student');
    }
  }

  Future<List<UserData>> getActiveTrainers() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/trainers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => UserData.fromJson(item)).toList();
    }

    return [];
  }

  Future<UserData?> createParentForStudent({
    required String studentId,
    required String phoneNumber,
    required String iin,
    required String fullName,
    required DateTime dateOfBirth,
    required String password,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/students/$studentId/create-parent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'phoneNumber': phoneNumber,
        'iin': iin,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['student'] != null) {
        return UserData.fromJson(data['student']);
      }
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Не удалось создать родителя');
    }

    return null;
  }

  Future<UserData?> attachParentToStudent({
    required String studentId,
    String? parentPhone,
    String? parentIin,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/students/$studentId/attach-parent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'parentPhone': parentPhone,
        'parentIin': parentIin,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['student'] != null) {
        return UserData.fromJson(data['student']);
      }
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Не удалось прикрепить родителя');
    }
    return null;
  }
}
