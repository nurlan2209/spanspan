import 'package:flutter/foundation.dart';

class UserData {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final double weight;
  final List<String> userType;
  final String? groupId;
  final List<UserData>? children;
  final UserData? parent;

  UserData({
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

  factory UserData.fromJson(Map<String, dynamic> json) {
    debugPrint('🟢🟢🟢 UserData.fromJson ВЫЗВАН 🟢🟢🟢');

    final rawUserType = json['userType'];
    debugPrint('🔍 rawUserType: $rawUserType, тип: ${rawUserType.runtimeType}');

    List<String> userTypeList;
    if (rawUserType is List) {
      userTypeList = List<String>.from(rawUserType.map((e) => e.toString()));
    } else if (rawUserType is String) {
      userTypeList = [rawUserType];
    } else {
      userTypeList = [];
    }

    debugPrint('✅ userTypeList: $userTypeList');

    return UserData(
      id: json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      iin: json['iin']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth:
          DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
          DateTime.now(),
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      userType: userTypeList,
      groupId: json['groupId']?.toString(),
      children: null,
      parent: null,
    );
  }

  bool hasRole(String role) => userType.contains(role);
  bool get isStudent => hasRole('student');
  bool get isTrainer => hasRole('trainer');
  bool get isParent => hasRole('parent');
  bool get isAdmin => hasRole('admin');
}