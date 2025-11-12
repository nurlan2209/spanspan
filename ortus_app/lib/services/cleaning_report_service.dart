import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cleaning_report_model.dart';
import 'auth_service.dart';

class CleaningReportService {
  Future<bool> createReport({
    required DateTime date,
    required List<String> zones,
    String? comment,
    required List<File> photos,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final uri = Uri.parse('${ApiConfig.baseUrl}/cleaning-reports');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['date'] = date.toIso8601String();

    for (var i = 0; i < zones.length; i++) {
      request.fields['zones[$i]'] = zones[i];
    }

    if (comment != null && comment.isNotEmpty) {
      request.fields['comment'] = comment;
    }

    for (final file in photos) {
      final multipartFile = await http.MultipartFile.fromPath(
        'photos',
        file.path,
      );
      request.files.add(multipartFile);
    }

    final response = await request.send();
    return response.statusCode == 201;
  }

  Future<List<CleaningReportModel>> getReports({String? staffId}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    var url = '${ApiConfig.baseUrl}/cleaning-reports';
    if (staffId != null && staffId.isNotEmpty) {
      url += '?staffId=$staffId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => CleaningReportModel.fromJson(e)).toList();
    }
    return [];
  }
}
