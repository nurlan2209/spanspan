import 'package:flutter/foundation.dart';

class UserData {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String? status;
  final DateTime? birthDate;
  final DateTime? createdAt;

  UserData({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    this.status,
    this.birthDate,
    this.createdAt,
  });

  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int a = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      a--;
    }
    return a;
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    debugPrint('🟢🟢🟢 UserData.fromJson ВЫЗВАН 🟢🟢🟢');

    return UserData(
      id: json['_id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      status: json['status']?.toString(),
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isDirector => role == 'director';
  bool get isManager => role == 'manager';
  bool get isTrainer => role == 'trainer';
  bool get isClient => role == 'client';
}
