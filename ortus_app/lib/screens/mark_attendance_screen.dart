import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import '../models/group_model.dart';
import '../models/schedule_model.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String? _selectedGroupId;
  String? _selectedScheduleId;
  DateTime _selectedDate = DateTime.now();
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = false;

  final statuses = {
    'present': 'Присутствовал',
    'absent': 'Отсутствовал',
    'sick': 'Болезнь',
    'competition': 'Соревнования',
    'excused': 'Уважительная',
  };

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Отметить посещаемость',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupSelector(),
            const SizedBox(height: 16),
            if (_selectedGroupId != null) _buildScheduleSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            if (_selectedGroupId != null && _selectedScheduleId != null)
              Center(
                child: CustomButton(
                  text: _attendanceRecords.isEmpty
                      ? 'Создать отметки'
                      : 'Загрузить отметки',
                  onPressed: _loadOrCreateAttendance,
                ),
              ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (_attendanceRecords.isNotEmpty)
              _buildAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Группа',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<GroupModel>>(
          future: GroupService().getAllGroups(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            // Фильтруем только группы текущего тренера
            final user = Provider.of<AuthProvider>(context, listen: false).user;
            final myGroups = snapshot.data!
                .where((g) => g.trainerName == user?.fullName)
                .toList();

            return DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: myGroups.map((group) {
                return DropdownMenuItem(
                  value: group.id,
                  child: Text(group.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGroupId = val;
                  _selectedScheduleId = null;
                  _attendanceRecords = [];
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расписание',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<ScheduleModel>>(
          future: ScheduleService().getScheduleByGroup(_selectedGroupId!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return DropdownButtonFormField<String>(
              value: _selectedScheduleId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: snapshot.data!.map((schedule) {
                return DropdownMenuItem(
                  value: schedule.id,
                  child: Text(
                    '${schedule.dayName} ${schedule.startTime}-${schedule.endTime}',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedScheduleId = val;
                  _attendanceRecords = [];
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата тренировки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
                _attendanceRecords = [];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Студенты',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._attendanceRecords.map((record) => _buildAttendanceCard(record)),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    record.studentName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.entries.map((entry) {
                final isSelected = record.status == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateAttendance(record, entry.key);
                    }
                  },
                  backgroundColor: AppColors.white,
                  selectedColor: _getStatusColor(entry.key),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
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
        return AppColors.primary;
    }
  }

  void _loadOrCreateAttendance() async {
    if (_selectedGroupId == null || _selectedScheduleId == null) return;

    setState(() => _isLoading = true);

    // Попытка загрузить существующие записи
    var records = await AttendanceService().getGroupAttendanceByDate(
      _selectedGroupId!,
      _selectedDate,
    );

    // Если записей нет - создаём новые
    if (records.isEmpty) {
      records = await AttendanceService().createAttendanceForGroup(
        groupId: _selectedGroupId!,
        scheduleId: _selectedScheduleId!,
        date: _selectedDate,
      );
    }

    setState(() {
      _attendanceRecords = records;
      _isLoading = false;
    });

    if (records.isEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет студентов в группе')));
    }
  }

  void _updateAttendance(AttendanceModel record, String newStatus) async {
    final success = await AttendanceService().markAttendance(
      record.id,
      newStatus,
    );

    if (success) {
      setState(() {
        final index = _attendanceRecords.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          _attendanceRecords[index] = AttendanceModel(
            id: record.id,
            scheduleId: record.scheduleId,
            groupId: record.groupId,
            groupName: record.groupName,
            studentId: record.studentId,
            studentName: record.studentName,
            date: record.date,
            status: newStatus,
            note: record.note,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Отметка обновлена: ${statuses[newStatus]}'),
          backgroundColor: _getStatusColor(newStatus),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
