import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/group_model.dart';

class GroupService {
  Future<Map<String, String>> _headers(String token) async {
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<GroupModel>> getGroups(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.groupsUrl),
      headers: await _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => GroupModel.fromJson(e)).toList();
    }
    throw Exception('Ошибка загрузки групп');
  }

  Future<List<GroupModel>> getMyEnrollments(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.groupsUrl}/my-enrollments'),
      headers: await _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => GroupModel.fromJson(e)).toList();
    }
    throw Exception('Ошибка загрузки записей');
  }

  Future<List<GroupModel>> getTrainerGroups(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.groupsUrl}/trainer'),
      headers: await _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => GroupModel.fromJson(e)).toList();
    }
    throw Exception('Ошибка загрузки групп тренера');
  }

  Future<GroupModel> createGroup(String token, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConfig.groupsUrl),
      headers: await _headers(token),
      body: json.encode(data),
    );
    if (res.statusCode == 201) {
      return GroupModel.fromJson(json.decode(res.body));
    }
    final msg = json.decode(res.body)['message'] ?? 'Ошибка создания группы';
    throw Exception(msg);
  }

  Future<void> confirmGroup(String token, String groupId) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/confirm'),
      headers: await _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Ошибка подтверждения');
  }

  Future<void> cancelGroup(String token, String groupId) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/cancel'),
      headers: await _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Ошибка отмены');
  }

  Future<List<Map<String, dynamic>>> getMembers(String token, String groupId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/members'),
      headers: await _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Ошибка загрузки участников');
  }

  Future<void> enroll(String token, String groupId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/enroll'),
      headers: await _headers(token),
    );
    if (res.statusCode != 200) {
      final msg = json.decode(res.body)['message'] ?? 'Ошибка записи';
      throw Exception(msg);
    }
  }

  Future<void> unenroll(String token, String groupId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.groupsUrl}/$groupId/enroll'),
      headers: await _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Ошибка отписки');
  }
}
