import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/photo_report_model.dart';
import 'auth_service.dart';

class PhotoReportService {
  Future<bool> createPhotoReport({
    required String type,
    String? relatedId,
    String? comment,
    required List<File> photos,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final uri = Uri.parse('${ApiConfig.baseUrl}/photo-reports');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type'] = type;

    if (relatedId != null && relatedId.isNotEmpty) {
      request.fields['relatedId'] = relatedId;
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

  Future<List<PhotoReportModel>> getPhotoReports({
    String? type,
    String? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final params = <String, String>{};
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    var url = '${ApiConfig.baseUrl}/photo-reports';
    if (params.isNotEmpty) {
      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      url += '?$query';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => PhotoReportModel.fromJson(e)).toList();
    }
    return [];
  }
}
