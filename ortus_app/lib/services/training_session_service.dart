import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

enum TrainingSessionStatus { notStarted, started, finished }

class TrainingSessionService {
  final _authService = AuthService();

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}'
        '-${normalized.month.toString().padLeft(2, '0')}'
        '-${normalized.day.toString().padLeft(2, '0')}';
  }

  TrainingSessionStatus _parseStatus(String? value) {
    switch (value) {
      case 'started':
        return TrainingSessionStatus.started;
      case 'finished':
        return TrainingSessionStatus.finished;
      default:
        return TrainingSessionStatus.notStarted;
    }
  }

  Future<Map<String, TrainingSessionStatus>> getStatuses(
    List<String> scheduleIds,
    DateTime date,
  ) async {
    if (scheduleIds.isEmpty) return {};
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Не удалось получить токен пользователя');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/training-sessions/status',
    ).replace(queryParameters: {
      'scheduleIds': scheduleIds.join(','),
      'date': _dateKey(date),
    });

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> raw =
          (data['statuses'] as Map?)?.cast<String, dynamic>() ?? {};
      return raw.map(
        (key, value) =>
            MapEntry(key, _parseStatus(value?.toString().toLowerCase())),
      );
    }

    throw Exception(_messageFromResponse(
      response.body,
      'Не удалось получить статусы тренировок',
    ));
  }

  Future<TrainingSessionStatus> getStatus(
    String scheduleId,
    DateTime date,
  ) async {
    final result = await getStatuses([scheduleId], date);
    return result[scheduleId] ?? TrainingSessionStatus.notStarted;
  }

  Future<void> startSession(String scheduleId, DateTime date) async {
    await _postAction(
      'start',
      {
        'scheduleId': scheduleId,
        'date': _dateKey(date),
      },
      'Не удалось начать тренировку',
    );
  }

  Future<void> finishSession(String scheduleId, DateTime date) async {
    await _postAction(
      'finish',
      {
        'scheduleId': scheduleId,
        'date': _dateKey(date),
      },
      'Не удалось завершить тренировку',
    );
  }

  Future<bool> hasSessionStarted(String scheduleId, DateTime date) async {
    final status = await getStatus(scheduleId, date);
    return status == TrainingSessionStatus.started;
  }

  Future<void> _postAction(
    String path,
    Map<String, dynamic> payload,
    String fallbackError,
  ) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Не удалось получить токен пользователя');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/training-sessions/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromResponse(response.body, fallbackError),
      );
    }
  }

  String _messageFromResponse(String body, String fallback) {
    try {
      final parsed = json.decode(body);
      if (parsed is Map<String, dynamic> && parsed['message'] is String) {
        return parsed['message'] as String;
      }
    } catch (_) {
      // ignore parse errors
    }
    return fallback;
  }
}
