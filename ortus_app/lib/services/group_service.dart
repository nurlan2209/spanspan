import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/group_model.dart';
import 'auth_service.dart';

class GroupService {
  Future<List<GroupModel>> getAllGroups() async {
    final response = await http.get(Uri.parse(ApiConfig.groupsUrl));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => GroupModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<dynamic>> getJoinRequests() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.groupsUrl}/requests'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> handleRequest(String requestId, String action) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.groupsUrl}/requests/handle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'requestId': requestId, 'action': action}),
    );

    return response.statusCode == 200;
  }
}
