import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _maxController = TextEditingController(text: '20');
  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();

  final _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  final Set<int> _selectedDays = {};
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 18, minute: 0);
  bool _loading = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
    );
    if (picked != null) setState(() => _scheduleTime = picked);
  }

  String get _timeLabel =>
      '${_scheduleTime.hour.toString().padLeft(2, '0')}:${_scheduleTime.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один день'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    final err = await context.read<GroupProvider>().createGroup({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'scheduleDays': _selectedDays.toList()..sort(),
      'scheduleTime': _timeLabel,
      'maxParticipants': int.parse(_maxController.text),
      'ageMin': int.parse(_ageMinController.text),
      'ageMax': int.parse(_ageMaxController.text),
    });
    setState(() => _loading = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать группу')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Основное', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Название группы *'),
                        validator: (v) => v!.trim().isEmpty ? 'Обязательное поле' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Описание'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Расписание', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      const Text('Дни недели *', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final selected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(_dayLabels[i]),
                            selected: selected,
                            onSelected: (v) => setState(() {
                              v ? _selectedDays.add(day) : _selectedDays.remove(day);
                            }),
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selected ? AppColors.primary : AppColors.black,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      const Text('Время *', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: AppColors.grey, size: 18),
                              const SizedBox(width: 10),
                              Text(_timeLabel, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Участники', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _maxController,
                        decoration: const InputDecoration(labelText: 'Максимум участников *'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Введите число больше 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageMinController,
                              decoration: const InputDecoration(labelText: 'Возраст от *'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Введите возраст' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ageMaxController,
                              decoration: const InputDecoration(labelText: 'Возраст до *'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                final max = int.tryParse(v ?? '');
                                final min = int.tryParse(_ageMinController.text);
                                if (max == null) return 'Введите возраст';
                                if (min != null && max < min) return 'Меньше мин.';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text('Создать группу',
                            style: TextStyle(color: AppColors.white, fontSize: 16)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    super.dispose();
  }
}
