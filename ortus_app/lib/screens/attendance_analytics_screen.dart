import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';
import '../utils/date_picker_helper.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  final String? studentId;

  const AttendanceAnalyticsScreen({super.key, this.studentId});

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  late Future<AttendanceStats?> _statsFuture;
  late Future<List<AttendanceModel>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    // По умолчанию - текущий месяц
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  void _loadData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final targetStudentId = widget.studentId ?? user?.id;

    if (targetStudentId != null) {
      setState(() {
        _statsFuture = AttendanceService().getStudentAttendanceStats(
          targetStudentId,
          startDate: _startDate,
          endDate: _endDate,
        );
        _recordsFuture = AttendanceService().getStudentAttendance(
          targetStudentId,
          startDate: _startDate,
          endDate: _endDate,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Посещаемость',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildRecordsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Период',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'С: ${_formatDate(_startDate)}',
                  () => _selectStartDate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  'По: ${_formatDate(_endDate)}',
                  () => _selectEndDate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickFilterChip('Этот месяц', _setCurrentMonth),
              _buildQuickFilterChip('Прошлый месяц', _setLastMonth),
              _buildQuickFilterChip('3 месяца', _setLast3Months),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<AttendanceStats?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Нет данных'));
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Процент посещаемости',
              '${stats.attendanceRate}%',
              Icons.pie_chart,
              AppColors.primary,
              subtitle: '${stats.present} из ${stats.total} тренировок',
            ),
            _buildStatCard(
              'Присутствовал',
              '${stats.present}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Пропущено',
              '${stats.absent}',
              Icons.cancel,
              Colors.red,
            ),
            if (stats.sick > 0)
              _buildStatCard(
                'Болезнь',
                '${stats.sick}',
                Icons.local_hospital,
                Colors.orange,
              ),
            if (stats.competition > 0)
              _buildStatCard(
                'Соревнования',
                '${stats.competition}',
                Icons.emoji_events,
                Colors.blue,
              ),
            if (stats.excused > 0)
              _buildStatCard(
                'Уважительная причина',
                '${stats.excused}',
                Icons.event_note,
                Colors.purple,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsSection() {
    return FutureBuilder<List<AttendanceModel>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 60, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  'Нет записей за выбранный период',
                  style: TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        final records = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История посещений',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...records.map((record) => _buildRecordCard(record)),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(AttendanceModel record) {
    final statusColor = _getStatusColor(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(record.status),
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(record.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.groupName,
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                  if (record.note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.note!,
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.statusText,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'sick':
        return Colors.orange;
      case 'competition':
        return Colors.blue;
      case 'excused':
        return Colors.purple;
      default:
        return AppColors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'sick':
        return Icons.local_hospital;
      case 'competition':
        return Icons.emoji_events;
      case 'excused':
        return Icons.event_note;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не выбрано';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _selectStartDate() async {
    final date = await showAppDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
      _loadData();
    }
  }

  void _selectEndDate() async {
    final date = await showAppDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
      _loadData();
    }
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    setState(() {
      _startDate = lastMonth;
      _endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
    });
    _loadData();
  }

  void _setLast3Months() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 2, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }
}
