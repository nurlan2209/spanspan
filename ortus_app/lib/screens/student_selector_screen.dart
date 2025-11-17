import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'attendance_analytics_screen.dart';

class StudentSelectorScreen extends StatelessWidget {
  const StudentSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.black,
          title: const Text(
            'Выбор ученика',
            style: TextStyle(color: AppColors.white),
          ),
        ),
        body: const Center(child: Text('Ошибка загрузки данных')),
      );
    }

    // Если ученик - сразу показываем его посещаемость
    if (user.isStudent) {
      return AttendanceAnalyticsScreen(studentId: user.id);
    }

    // Если родитель - показываем список детей
    if (user.isParent && user.children != null && user.children!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.black,
          title: const Text(
            'Выберите ребёнка',
            style: TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: user.children!.length,
          itemBuilder: (context, index) {
            final child = user.children![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    child.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  child.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(child.phoneNumber),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.grey,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttendanceAnalyticsScreen(studentId: child.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Посещаемость',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: const Center(child: Text('Нет доступных учеников')),
    );
  }
}
