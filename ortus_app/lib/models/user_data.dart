import 'package:flutter/foundation.dart';

class UserData {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String? status;
  final DateTime? createdAt;

  UserData({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    this.status,
    this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    debugPrint('🟢🟢🟢 UserData.fromJson ВЫЗВАН 🟢🟢🟢');

    return UserData(
      id: json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isDirector => role == 'director';
  bool get isManager => role == 'manager';
  bool get isTrainer => role == 'trainer';
  bool get isClient => role == 'client';
}
