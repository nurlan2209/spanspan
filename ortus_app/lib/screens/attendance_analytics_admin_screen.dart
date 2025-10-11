import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';

class AttendanceAnalyticsAdminScreen extends StatefulWidget {
  const AttendanceAnalyticsAdminScreen({super.key});

  @override
  State<AttendanceAnalyticsAdminScreen> createState() =>
      _AttendanceAnalyticsAdminScreenState();
}

class _AttendanceAnalyticsAdminScreenState
    extends State<AttendanceAnalyticsAdminScreen> {
  late Future<Map<String, dynamic>?> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _analyticsFuture = AnalyticsService().getAttendanceAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Аналитика посещаемости',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Нет данных для отображения'));
          }

          final analytics = snapshot.data!;
          final overall = analytics['overall'];
          final byGroup = analytics['byGroup'] as List;
          final topStudents = (analytics['topStudents'] as List)
              .map(
                (s) => {
                  'user': UserModel.fromJson(s['student']),
                  'rate': s['attendanceRate'],
                },
              )
              .toList();
          final lowAttendanceStudents =
              (analytics['lowAttendanceStudents'] as List)
                  .map(
                    (s) => {
                      'user': UserModel.fromJson(s['student']),
                      'rate': s['attendanceRate'],
                    },
                  )
                  .toList();

          return RefreshIndicator(
            onRefresh: () async => _loadAnalytics(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildOverallSummary(overall),
                const SizedBox(height: 24),
                _buildGroupsList(byGroup),
                const SizedBox(height: 24),
                _buildStudentList(
                  '💎 Лучшие студенты',
                  topStudents,
                  AppColors.primary,
                ),
                const SizedBox(height: 24),
                _buildStudentList(
                  '🤔 С низкой посещаемостью',
                  lowAttendanceStudents,
                  Colors.redAccent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallSummary(Map<String, dynamic> overall) {
    final double rate = overall['total'] > 0
        ? (overall['present'] / overall['total'] * 100)
        : 0.0;
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Общая посещаемость',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${overall['present']} из ${overall['total']} тренировок',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(List<dynamic> byGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Посещаемость по группам',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...byGroup.map((group) {
          final rate = (group['attendanceRate'] ?? 0).toDouble();
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group['groupName'] ?? 'Неизвестная группа',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: rate > 75
                              ? Colors.green
                              : (rate > 50 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: AppColors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate > 75
                          ? Colors.green
                          : (rate > 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${group['presentCount']} посещений из ${group['totalLessons']}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStudentList(
    String title,
    List<Map<String, dynamic>> students,
    Color highlightColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        students.isEmpty
            ? const Text(
                'Нет студентов для отображения',
                style: TextStyle(color: AppColors.grey),
              )
            : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: students.map((studentData) {
                    final user = studentData['user'] as UserModel;
                    final rate = (studentData['rate'] ?? 0).toDouble();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: highlightColor.withOpacity(0.2),
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0] : '?',
                          style: TextStyle(
                            color: highlightColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: highlightColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}
