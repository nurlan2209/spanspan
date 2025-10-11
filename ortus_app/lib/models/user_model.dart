import 'package:/flutter/foundation.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final double weight;
  final List<String> userType;
  final String? groupId;
  final List<UserModel>? children;
  final UserModel? parent;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.iin,
    required this.fullName,
    required this.dateOfBirth,
    required this.weight,
    required this.userType,
    this.groupId,
    this.children,
    this.parent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Эта "защита" (try-catch) не даст приложению упасть
    try {
      return UserModel(
        id: json['_id'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        iin: json['iin'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        dateOfBirth:
            DateTime.tryParse(json['dateOfBirth'] as String? ?? '') ??
            DateTime.now(),
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        // ГЛАВНОЕ ИСПРАВЛЕНИЕ: Правильно обрабатываем МАССИВ ролей
        userType: json['userType'] is List
            ? List<String>.from(json['userType'])
            : [],
        groupId: json['groupId'] != null
            ? (json['groupId'] is String
                  ? json['groupId']
                  : json['groupId']['_id'])
            : null,
        children: json['children'] is List
            ? (json['children'] as List)
                  .map((child) => UserModel.fromJson(child))
                  .toList()
            : null,
        parent: json['parentId'] is Map<String, dynamic>
            ? UserModel.fromJson(json['parentId'])
            : null,
      );
    } catch (e) {
      debugPrint('!!! ОШИБКА ПРИ ПАРСИНГЕ UserModel: $e');
      debugPrint('!!! ВХОДНЫЕ ДАННЫЕ (JSON): $json');
      // Возвращаем "пустую" модель, чтобы приложение не падало
      return UserModel(
        id: '',
        phoneNumber: '',
        iin: '',
        fullName: 'Ошибка данных',
        dateOfBirth: DateTime.now(),
        weight: 0,
        userType: [],
      );
    }
  }

  bool hasRole(String role) => userType.contains(role);
  bool get isStudent => hasRole('student');
  bool get isTrainer => hasRole('trainer');
  bool get isParent => hasRole('parent');
  bool get isAdmin => hasRole('admin');
}
