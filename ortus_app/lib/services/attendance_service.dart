import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/attendance_model.dart';
import 'auth_service.dart';

class AttendanceService {
  Future<List<AttendanceModel>> createAttendanceForGroup({
    required String groupId,
    required String scheduleId,
    required DateTime date,
  }) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'groupId': groupId,
        'scheduleId': scheduleId,
        'date': date.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      List data = json.decode(response.body);
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> markAttendance(String id, String status, {String? note}) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/attendance/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status, 'note': note}),
    );

    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(
        response.body,
        'Не удалось обновить отметку',
      ));
    }
  }

  Future<List<AttendanceModel>> getGroupAttendanceByDate(
    String groupId,
    DateTime date,
  ) async {
    final token = await AuthService().getToken();
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/attendance/group/$groupId/$dateStr'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<AttendanceModel>> getStudentAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/attendance/student/$studentId';

    if (startDate != null || endDate != null) {
      url += '?';
      if (startDate != null) {
        url += 'startDate=${startDate.toIso8601String()}&';
      }
      if (endDate != null) {
        url += 'endDate=${endDate.toIso8601String()}';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<AttendanceStats?> getStudentAttendanceStats(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/attendance/student/$studentId/stats';

    if (startDate != null || endDate != null) {
      url += '?';
      if (startDate != null) {
        url += 'startDate=${startDate.toIso8601String()}&';
      }
      if (endDate != null) {
        url += 'endDate=${endDate.toIso8601String()}';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return AttendanceStats.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<AttendanceStats?> getGroupAttendanceStats(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/attendance/group/$groupId/stats';

    if (startDate != null || endDate != null) {
      url += '?';
      if (startDate != null) {
        url += 'startDate=${startDate.toIso8601String()}&';
      }
      if (endDate != null) {
        url += 'endDate=${endDate.toIso8601String()}';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return AttendanceStats.fromJson(json.decode(response.body));
    }
    return null;
  }

  String _messageFromResponse(String body, String fallback) {
    try {
      final parsed = json.decode(body);
      if (parsed is Map && parsed['message'] is String) {
        return parsed['message'] as String;
      }
    } catch (_) {
      // ignore
    }
    return fallback;
  }
}
