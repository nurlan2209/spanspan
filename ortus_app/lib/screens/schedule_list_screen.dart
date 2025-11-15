import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_model.dart';
import '../providers/auth_provider.dart';
import '../services/schedule_service.dart';
import '../services/training_session_service.dart';
import '../utils/constants.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final _scheduleService = ScheduleService();
  final _sessionService = TrainingSessionService();
  final DateTime _today = DateTime.now();

  List<ScheduleModel> _schedules = [];
  Map<String, TrainingSessionStatus> _todayStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _scheduleService.getAllSchedules();
    if (!mounted) return;
    setState(() {
      _schedules = data;
      _isLoading = false;
    });
    await _loadTodayStatuses();
  }

  Future<void> _loadTodayStatuses() async {
    final todayIndex = _today.weekday - 1;
    if (todayIndex < 0) return;
    final todays = _schedules.where((s) => s.dayOfWeek == todayIndex).toList();
    if (todays.isEmpty) {
      if (mounted) setState(() => _todayStatuses = {});
      return;
    }

    try {
      final statuses = await _sessionService.getStatuses(
        todays.map((s) => s.id).toList(),
        _today,
      );
      if (mounted) {
        setState(() => _todayStatuses = statuses);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Не удалось обновить статусы тренировок: $e');
      setState(() => _todayStatuses = {});
    }
  }

  bool _isTodaySchedule(ScheduleModel schedule) =>
      schedule.dayOfWeek == _today.weekday - 1;

  DateTime _combineTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(_today.year, _today.month, _today.day, hour, minute);
  }

  bool _isWithinStartWindow(ScheduleModel schedule) {
    final start = _combineTime(schedule.startTime);
    final now = DateTime.now();
    final windowStart = start.subtract(const Duration(minutes: 10));
    final windowEnd = start.add(const Duration(minutes: 10));
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  bool _isFinishWindowOpen(ScheduleModel schedule) {
    final end = _combineTime(schedule.endTime);
    final now = DateTime.now();
    final windowStart = end.subtract(const Duration(minutes: 5));
    final windowEnd = end.add(const Duration(hours: 1));
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  Future<void> _handleStart(ScheduleModel schedule) async {
    if (!_isWithinStartWindow(schedule)) {
      _showSnack(
        'Кнопка станет активна за 10 минут до начала тренировки.',
      );
      return;
    }
    try {
      await _sessionService.startSession(schedule.id, _today);
      await _loadTodayStatuses();
      _showSnack('Тренировка начата, можно отмечать посещаемость.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleFinish(ScheduleModel schedule) async {
    if (!_isFinishWindowOpen(schedule)) {
      _showSnack('Завершить тренировку можно после её начала.');
      return;
    }
    try {
      await _sessionService.finishSession(schedule.id, _today);
      await _loadTodayStatuses();
      _showSnack('Тренировка завершена.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isTrainer = user?.isTrainer == true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.black,
        title: const Text(
          'Расписание',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      floatingActionButton: isTrainer
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                await Navigator.pushNamed(context, '/create-schedule');
                await _loadData();
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _schedules.isEmpty
                  ? _buildEmptyState()
                  : _buildScheduleList(isTrainer),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 160),
        Icon(Icons.calendar_today, size: 80, color: AppColors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Расписание отсутствует',
            style: TextStyle(color: AppColors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(bool isTrainer) {
    final grouped = <int, List<ScheduleModel>>{};
    for (final schedule in _schedules) {
      grouped.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
    }
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final entries = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entries.first.dayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...entries.map((schedule) {
              final isToday = _isTodaySchedule(schedule);
              final status =
                  _todayStatuses[schedule.id] ?? TrainingSessionStatus.notStarted;
              final showControls = isTrainer && isToday;
              final canStart =
                  showControls && status == TrainingSessionStatus.notStarted;
              final canFinish =
                  showControls && status == TrainingSessionStatus.started;
              return _ScheduleCard(
                schedule: schedule,
                status: status,
                showControls: showControls,
                canStart: canStart && _isWithinStartWindow(schedule),
                canFinish: canFinish && _isFinishWindowOpen(schedule),
                onStart: showControls ? () => _handleStart(schedule) : null,
                onFinish: showControls ? () => _handleFinish(schedule) : null,
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final TrainingSessionStatus status;
  final bool showControls;
  final bool canStart;
  final bool canFinish;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;

  const _ScheduleCard({
    required this.schedule,
    required this.status,
    required this.showControls,
    required this.canStart,
    required this.canFinish,
    this.onStart,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.groupName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Text('${schedule.startTime} - ${schedule.endTime}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(schedule.location)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(
                  status == TrainingSessionStatus.finished
                      ? Icons.check_circle
                      : status == TrainingSessionStatus.started
                          ? Icons.play_arrow
                          : Icons.pause_circle_outline,
                  size: 18,
                  color: _statusColor,
                ),
                label: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: _statusColor.withValues(alpha: 0.1),
              ),
            ),
            if (showControls) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canStart ? onStart : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Начать тренировку'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canFinish ? onFinish : null,
                      icon: const Icon(Icons.flag),
                      label: const Text('Завершить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white, 
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Кнопки активны в течение 10 минут вокруг начала тренировки.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case TrainingSessionStatus.started:
        return Colors.orange;
      case TrainingSessionStatus.finished:
        return Colors.green;
      case TrainingSessionStatus.notStarted:
        return AppColors.grey;
    }
  }

  String get _statusLabel {
    switch (status) {
      case TrainingSessionStatus.started:
        return 'Тренировка идёт';
      case TrainingSessionStatus.finished:
        return 'Завершено';
      case TrainingSessionStatus.notStarted:
        return 'Не начато';
    }
  }
}
