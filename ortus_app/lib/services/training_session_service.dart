import 'package:shared_preferences/shared_preferences.dart';

enum TrainingSessionStatus { notStarted, started, finished }

class TrainingSessionService {
  static const _sessionPrefix = 'training_session_';

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}'
        '-${normalized.month.toString().padLeft(2, '0')}'
        '-${normalized.day.toString().padLeft(2, '0')}';
  }

  String _sessionKey(String scheduleId, DateTime date) =>
      '$_sessionPrefix${scheduleId}_${_dateKey(date)}';

  Future<TrainingSessionStatus> getStatus(
    String scheduleId,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_sessionKey(scheduleId, date));
    switch (value) {
      case 'started':
        return TrainingSessionStatus.started;
      case 'finished':
        return TrainingSessionStatus.finished;
      default:
        return TrainingSessionStatus.notStarted;
    }
  }

  Future<void> startSession(String scheduleId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey(scheduleId, date), 'started');
  }

  Future<void> finishSession(String scheduleId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey(scheduleId, date), 'finished');
  }

  Future<bool> hasSessionStarted(String scheduleId, DateTime date) async {
    final status = await getStatus(scheduleId, date);
    return status == TrainingSessionStatus.started ||
        status == TrainingSessionStatus.finished;
  }
}
