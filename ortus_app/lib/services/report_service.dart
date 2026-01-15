import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/report_model.dart';
import 'auth_service.dart';

class ReportService {
  Future<bool> createReport({
    required DateTime trainingDate,
    required String slot,
    required String comment,
    required List<File> attachments,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.reportsUrl),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['trainingDate'] = trainingDate.toIso8601String();
    request.fields['slot'] = slot;
    request.fields['comment'] = comment;

    for (final file in attachments) {
      request.files.add(
        await http.MultipartFile.fromPath('attachments', file.path),
      );
    }

    final response = await http.Response.fromStream(await request.send());
    return response.statusCode == 201;
  }

  Future<List<ReportModel>> getMyReports() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.reportsUrl}/my'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => ReportModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ReportModel>> getReports({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? trainerId,
    bool? isLate,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final params = <String, String>{};
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();
    if (trainerId != null && trainerId.isNotEmpty) {
      params['trainerId'] = trainerId;
    }
    if (isLate != null) params['isLate'] = isLate.toString();

    var url = ApiConfig.reportsUrl;
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
      final data = json.decode(response.body) as List;
      return data.map((e) => ReportModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> deleteReport(String id) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${ApiConfig.reportsUrl}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
