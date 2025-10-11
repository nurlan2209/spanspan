import 'package:flutter/material.dart';
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

          if (!snapshot.hasData) {
            return const Center(child: Text('Нет данных'));
          }

          final data = snapshot.data!;
          final overall = data['overall'];
          final byGroup = data['byGroup'] as List;
          final lowAttendance = data['lowAttendanceStudents'] as List;
          final topStudents = data['topAttendanceStudents'] as List;

          return RefreshIndicator(
            onRefresh: () async => _loadAnalytics(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverallCard(overall),
                const SizedBox(height: 20),
                _buildGroupsList(byGroup),
                const SizedBox(height: 20),
                if (topStudents.isNotEmpty) _buildTopStudents(topStudents),
                const SizedBox(height: 20),
                if (lowAttendance.isNotEmpty)
                  _buildLowAttendanceStudents(lowAttendance),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallCard(Map<String, dynamic> overall) {
    final rate = double.parse(overall['attendanceRate'].toString());
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...byGroup.map((group) {
          final rate = group['attendanceRate'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expande