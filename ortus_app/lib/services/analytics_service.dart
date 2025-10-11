import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AnalyticsService {
  Future<Map<String, dynamic>?> getFinancialAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/analytics/financial';

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
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getStudentsAnalytics() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/students'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPaymentsAnalytics({
    int? month,
    int? year,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/analytics/payments';

    if (month != null || year != null) {
      url += '?';
      if (month != null) url += 'month=$month&';
      if (year != null) url += 'year=$year';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  // НОВОЕ
  Future<Map<String, dynamic>?> getAttendanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/analytics/attendance';

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
      return json.decode(response.body);
    }
    return null;
  }

  // НОВОЕ
  Future<List<dynamic>?> compareGroups({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/analytics/compare-groups';

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
      return json.decode(response.body);
    }
    return null;
  }

  // НОВОЕ
  Future<Map<String, dynamic>?> getDashboard() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/dashboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
