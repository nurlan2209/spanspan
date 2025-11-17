import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  String? _selectedGroupId;
  int _selectedDay = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  final _locationController = TextEditingController(text: 'Зал ORTUS');
  bool _isLoading = false;
  bool _groupHasStudents = true;
  bool _checkingStudents = false;
  int _groupStudentsCount = 0;
  final _userService = UserService();

  final days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkGroupStudents(String? groupId) async {
    if (groupId == null) {
      setState(() {
        _groupHasStudents = false;
        _groupStudentsCount = 0;
        _checkingStudents = false;
      });
      return;
    }
    setState(() {
      _checkingStudents = true;
      _groupHasStudents = true;
      _groupStudentsCount = 0;
    });
    final students = await _userService.getStudents(groupId: groupId);
    if (!mounted) return;
    setState(() {
      _groupStudentsCount = students.length;
      _groupHasStudents = students.isNotEmpty;
      _checkingStudents = false;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Добавить расписание',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                final groups = snapshot.data!;
                final user =
                    Provider.of<AuthProvider>(context, listen: false).user;
                List<GroupModel> availableGroups = groups;
                if (user?.isTrainer == true &&
                    user?.isAdmin != true &&
                    user?.hasRole('director') != true) {
                  availableGroups = groups
                      .where((group) => group.trainerId == user?.id)
                      .toList();
                }

                final currentGroupId = availableGroups
                        .any((g) => g.id == _selectedGroupId)
                    ? _selectedGroupId
                    : null;

                if (availableGroups.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      'У вас пока нет групп для создания расписания. Обратитесь к администратору.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: currentGroupId,
                  decoration: _inputDecoration('Группа'),
                  items: availableGroups.map((group) {
                    return DropdownMenuItem(
                      value: group.id,
                      child: Text('${group.name} (${group.trainerName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedGroupId = val);
                    _checkGroupStudents(val);
                  },
                );
              },
            ),
            if (_checkingStudents)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (!_groupHasStudents && _selectedGroupId != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'В этой группе пока нет учеников. Добавьте их перед созданием расписания.',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              )
            else if (_groupStudentsCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Студентов в группе: $_groupStudentsCount',
                  style: const TextStyle(color: AppColors.grey),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'День недели',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: _inputDecoration('День недели'),
              items: List.generate(7, (index) {
                return DropdownMenuItem(value: index, child: Text(days[index]));
              }),
              onChanged: (val) => setState(() => _selectedDay = val!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Начало',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() => _startTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _startTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Конец',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time != null) {
                            setState(() => _endTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _endTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Локация',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: _inputDecoration('Локация'),
            ),
            const SizedBox(height: 30),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : CustomButton(text: 'Создать', onPressed: _createSchedule),
            ),
          ],
        ),
      ),
    );
  }

  void _createSchedule() async {
    if (_selectedGroupId == null) return;
    if (!_groupHasStudents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одного ученика в группу.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/schedules'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'groupId': _selectedGroupId,
        'dayOfWeek': _selectedDay,
        'startTime':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'endTime':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'location': _locationController.text,
      }),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Расписание добавлено'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания расписания')),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

}
