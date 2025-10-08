import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ScheduleService {
  Future<List<ScheduleModel>> getAllSchedules() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedules'),
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => ScheduleModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<ScheduleModel>> getScheduleByGroup(String groupId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedules/group/$groupId'),
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => ScheduleModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> createSchedule(Map<String, dynamic> scheduleData) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/schedules'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(scheduleData),
    );

    return response.statusCode == 201;
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
