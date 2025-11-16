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
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      _analyticsFuture = AnalyticsService().getAttendanceAnalytics(
        startDate: startOfMonth,
        endDate: now,
      );
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

          final analytics = snapshot.data ?? {};
          final overall = Map<String, dynamic>.from(
            (analytics['overall'] ?? {}) as Map? ?? {},
          );
          final byGroup = List<Map<String, dynamic>>.from(
            analytics['byGroup'] ?? const [],
          );
          final absencesByGroup = <String, List<Map<String, dynamic>>>{};
          for (final group in byGroup) {
            final abs = List<Map<String, dynamic>>.from(group['absences'] ?? []);
            absencesByGroup[group['groupId']?.toString() ?? ''] = abs;
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAnalytics(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildOverallSummary(overall),
                const SizedBox(height: 24),
                _buildGroupsList(byGroup),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallSummary(Map<String, dynamic> overall) {
    final total = (overall['total'] ?? 0) as num;
    final present = (overall['present'] ?? 0) as num;
    final double rate = total > 0 ? (present / total * 100) : 0.0;
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
              '${overall['present'] ?? 0} из ${overall['total'] ?? 0} тренировок',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
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
          final absences =
              List<Map<String, dynamic>>.from(group['absences'] ?? const []);
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showGroupDetails(group, absences),
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
                      backgroundColor: AppColors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rate > 75
                            ? Colors.green
                            : (rate > 50 ? Colors.orange : Colors.red),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Тренировок: ${group['total'] ?? 0}, посещено: ${group['present'] ?? 0}, пропусков: ${group['absent'] ?? 0}',
                      style:
                          const TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                    if (absences.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Нажмите, чтобы увидеть список пропусков',
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showGroupDetails(
    Map<String, dynamic> group,
    List<Map<String, dynamic>> absences,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group['groupName'] ?? 'Группа',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Тренировок: ${group['total'] ?? 0} • Посещено: ${group['present'] ?? 0} • Пропусков: ${group['absent'] ?? 0}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Пропуски по студентам',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (absences.isEmpty)
                const Text('Нет данных о пропусках')
              else
                ...absences.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['studentName'] ?? 'Без имени'),
                    trailing: Text('${item['absences'] ?? 0}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
