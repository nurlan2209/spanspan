import 'package:flutter/foundation.dart';

/// Новая модель пользователя (полностью совместима с UserModel)
class UserDto {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final List<String> userType; // ✅ ПЕРЕИМЕНОВАЛ ОБРАТНО
  final String? groupId;
  final List<UserDto>? children; // ✅ ДОБАВИЛ
  final UserDto? parent; // ✅ ДОБАВИЛ

  UserDto({
    required this.id,
    required this.phoneNumber,
    required this.iin,
    required this.fullName,
    required this.dateOfBirth,
    required this.userType,
    this.groupId,
    this.children,
    this.parent,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    debugPrint('🆕 [UserDto] Создание из JSON...');
    debugPrint('📦 JSON: $json');

    try {
      // Безопасное извлечение userType
      List<String> extractUserType(dynamic value) {
        debugPrint('🔍 Извлечение userType: $value (${value.runtimeType})');
        if (value == null) return [];
        if (value is List) {
          final result = value.map((e) => e.toString()).toList();
          debugPrint('✅ userType (List): $result');
          return result;
        }
        if (value is String) {
          debugPrint('✅ userType (String): [$value]');
          return [value];
        }
        return [value.toString()];
      }

      final userType = extractUserType(json['userType']);

      final dto = UserDto(
        id: (json['_id'] ?? '').toString(),
        phoneNumber: (json['phoneNumber'] ?? '').toString(),
        iin: (json['iin'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        dateOfBirth:
            DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
            DateTime.now(),
        userType: userType,
        groupId: json['groupId']?.toString(),
        // ✅ ДОБАВИЛ ПАРСИНГ children
        children: json['children'] is List
            ? (json['children'] as List)
                  .map(
                    (child) => UserDto.fromJson(child as Map<String, dynamic>),
                  )
                  .toList()
            : null,
        // ✅ ДОБАВИЛ ПАРСИНГ parent
        parent: json['parentId'] is Map<String, dynamic>
            ? UserDto.fromJson(json['parentId'] as Map<String, dynamic>)
            : null,
      );

      debugPrint('✅ UserDto создан: ${dto.fullName}, роли: ${dto.userType}');
      return dto;
    } catch (e, stack) {
      debugPrint('❌❌❌ ОШИБКА UserDto.fromJson ❌❌❌');
      debugPrint('Ошибка: $e');
      debugPrint('Stack: $stack');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'phoneNumber': phoneNumber,
    'iin': iin,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'userType': userType,
    'groupId': groupId,
    'children': children?.map((c) => c.toJson()).toList(),
    'parentId': parent?.toJson(),
  };

  // ✅ Вспомогательные методы (полная совместимость с UserModel)
  bool hasRole(String role) => userType.contains(role);
  bool get isStudent => hasRole('student');
  bool get isTrainer => hasRole('trainer');
  bool get isParent => hasRole('parent');
  bool get isAdmin => hasRole('admin');

  @override
  String toString() =>
      'UserDto(id: $id, fullName: $fullName, userType: $userType)';
}
