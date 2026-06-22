import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class GroupProvider extends ChangeNotifier {
  final _service = GroupService();
  final _auth = AuthService();

  List<GroupModel> _groups = [];
  List<GroupModel> _myEnrollments = [];
  List<GroupModel> _trainerGroups = [];
  bool _loading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get myEnrollments => _myEnrollments;
  List<GroupModel> get trainerGroups => _trainerGroups;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> _token() => _auth.getToken();

  Future<void> loadGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _token();
      _groups = await _service.getGroups(token!);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMyEnrollments() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _token();
      _myEnrollments = await _service.getMyEnrollments(token!);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadTrainerGroups() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _token();
      _trainerGroups = await _service.getTrainerGroups(token!);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createGroup(Map<String, dynamic> data) async {
    try {
      final token = await _token();
      final group = await _service.createGroup(token!, data);
      _trainerGroups.insert(0, group);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> confirmGroup(String groupId) async {
    try {
      final token = await _token();
      await _service.confirmGroup(token!, groupId);
      final i = _trainerGroups.indexWhere((g) => g.id == groupId);
      if (i != -1) {
        _trainerGroups[i] = GroupModel(
          id: _trainerGroups[i].id,
          title: _trainerGroups[i].title,
          description: _trainerGroups[i].description,
          trainerId: _trainerGroups[i].trainerId,
          trainerName: _trainerGroups[i].trainerName,
          scheduleDays: _trainerGroups[i].scheduleDays,
          scheduleTime: _trainerGroups[i].scheduleTime,
          maxParticipants: _trainerGroups[i].maxParticipants,
          ageMin: _trainerGroups[i].ageMin,
          ageMax: _trainerGroups[i].ageMax,
          status: 'confirmed',
          enrolledCount: _trainerGroups[i].enrolledCount,
          isEnrolled: _trainerGroups[i].isEnrolled,
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelGroup(String groupId) async {
    try {
      final token = await _token();
      await _service.cancelGroup(token!, groupId);
      final i = _trainerGroups.indexWhere((g) => g.id == groupId);
      if (i != -1) {
        _trainerGroups[i] = GroupModel(
          id: _trainerGroups[i].id,
          title: _trainerGroups[i].title,
          description: _trainerGroups[i].description,
          trainerId: _trainerGroups[i].trainerId,
          trainerName: _trainerGroups[i].trainerName,
          scheduleDays: _trainerGroups[i].scheduleDays,
          scheduleTime: _trainerGroups[i].scheduleTime,
          maxParticipants: _trainerGroups[i].maxParticipants,
          ageMin: _trainerGroups[i].ageMin,
          ageMax: _trainerGroups[i].ageMax,
          status: 'cancelled',
          enrolledCount: _trainerGroups[i].enrolledCount,
          isEnrolled: _trainerGroups[i].isEnrolled,
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getMembers(String groupId) async {
    final token = await _token();
    return _service.getMembers(token!, groupId);
  }

  Future<String?> enroll(String groupId) async {
    try {
      final token = await _token();
      await _service.enroll(token!, groupId);
      await loadGroups();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> unenroll(String groupId) async {
    try {
      final token = await _token();
      await _service.unenroll(token!, groupId);
      await loadGroups();
      await loadMyEnrollments();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
