import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _groupService = GroupService();
  final _userService = UserService();

  late Future<List<UserData>> _trainersFuture;
  String? _selectedTrainerId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trainersFuture = _userService.getActiveTrainers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Создать группу', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название группы (например, 2024-3)',
                  prefixIcon: const Icon(Icons.group, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Назначить тренера',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<UserData>>(
                future: _trainersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final trainers = snapshot.data ?? [];
                  if (trainers.isNotEmpty && _selectedTrainerId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedTrainerId == null) {
                        setState(() => _selectedTrainerId = trainers.first.id);
                      }
                    });
                  }
                  if (trainers.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Нет активных тренеров. Сначала создайте аккаунт тренера.',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedTrainerId,
                    items: trainers
                        .map(
                          (trainer) => DropdownMenuItem(
                            value: trainer.id,
                            child: Text(
                              '${trainer.fullName} (${trainer.phoneNumber})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedTrainerId = value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Выберите тренера',
                    ),
                    validator: (value) =>
                        value == null ? 'Выберите тренера для группы' : null,
                  );
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : CustomButton(
                      text: 'Создать',
                      onPressed: _createGroup,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала создайте и выберите тренера'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final isCreated = await _groupService.createGroup(
      name: _nameController.text.trim(),
      trainerId: _selectedTrainerId!,
    );
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (isCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Группа создана'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось создать группу'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
