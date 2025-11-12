import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/news_model.dart';
import 'auth_service.dart';

class NewsService {
  Future<List<NewsModel>> getAllNews({
    String? category,
    String? groupId,
    String? type,
  }) async {
    String url = '${ApiConfig.baseUrl}/news';

    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (groupId != null) params['groupId'] = groupId;
    if (type != null) params['type'] = type;

    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => NewsModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<NewsModel?> getNewsById(String id) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/news/$id'));

    if (response.statusCode == 200) {
      return NewsModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<NewsModel?> createNews(Map<String, dynamic> newsData) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/news'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(newsData),
    );

    if (response.statusCode == 201) {
      return NewsModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> updateNews(String id, Map<String, dynamic> newsData) async {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/news/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(newsData),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteNews(String id) async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/news/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<bool> togglePinNews(String id) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/news/$id/pin'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
