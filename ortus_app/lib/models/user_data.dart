import 'package:flutter/foundation.dart';

class UserData {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final List<String> userType;
  final String? status;
  final String? groupId;
  final String? groupName;
  final DateTime? createdAt;
  final List<UserData>? children;
  final UserData? parent;

  UserData({
    required this.id,
    required this.phoneNumber,
    required this.iin,
    required this.fullName,
    required this.dateOfBirth,
    required this.userType,
    this.status,
    this.groupId,
    this.groupName,
    this.createdAt,
    this.children,
    this.parent,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    debugPrint('🟢🟢🟢 UserData.fromJson ВЫЗВАН 🟢🟢🟢');

    String? resolvedGroupId;
    String? resolvedGroupName;
    final groupData = json['groupId'];
    if (groupData is Map) {
      resolvedGroupId = groupData['_id']?.toString();
      resolvedGroupName = groupData['name']?.toString();
    } else if (groupData is String) {
      resolvedGroupId = groupData;
    }

    return UserData(
      id: json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      iin: json['iin']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth:
          DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
          DateTime.now(),
      userType: _parseRoles(json['userType']),
      status: json['status']?.toString(),
      groupId: resolvedGroupId,
      groupName: resolvedGroupName,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      children: null,
      parent: json['parentId'] is Map<String, dynamic>
          ? UserData._fromPartial(json['parentId'] as Map<String, dynamic>)
          : null,
    );
  }

  bool hasRole(String role) => userType.contains(role);
  bool get isStudent => hasRole('student');
  bool get isTrainer => hasRole('trainer');
  bool get isParent => hasRole('parent');
  bool get isAdmin => hasRole('admin');

  static List<String> _parseRoles(dynamic raw) {
    if (raw is List) {
      return List<String>.from(raw.map((e) => e.toString()));
    }
    if (raw is String) {
      return [raw];
    }
    return <String>[];
  }

  factory UserData._fromPartial(Map<String, dynamic> json) {
    return UserData(
      id: json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      iin: json['iin']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth:
          DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
          DateTime.now(),
      userType: _parseRoles(
        json.containsKey('userType') && json['userType'] != null
            ? json['userType']
            : ['parent'],
      ),
      status: json['status']?.toString(),
      groupId: null,
      groupName: null,
      createdAt: null,
      children: null,
      parent: null,
    );
  }
}
