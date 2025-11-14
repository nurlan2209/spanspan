import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_picker_helper.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedGroupId;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _iinController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Создать аккаунт',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Карточка студента',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Номер телефона'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Введите номер телефона' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iinController,
                decoration: const InputDecoration(labelText: 'ИИН'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.length != 12 ? 'ИИН должен быть 12 цифр' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО'),
                validator: (value) => value!.isEmpty ? 'Введите ФИО' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Пароль минимум 6 символов' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _dateOfBirth == null
                      ? 'Дата рождения'
                      : _dateOfBirth!.toLocal().toString().split(' ').first,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showAppDatePicker(
                    context: context,
                    initialDate: DateTime(2010),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _dateOfBirth = picked);
                  }
                },
              ),
              FutureBuilder<List<GroupModel>>(
                future: GroupService().getAllGroups(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                    hint: const Text('Назначить группу (опционально)'),
                    onChanged: (value) => setState(() => _selectedGroupId = value),
                    items: snapshot.data!
                        .map(
                          (group) => DropdownMenuItem(
                            value: group.id,
                            child: Text(group.name),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Создать аккаунт',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate() || _dateOfBirth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserService().createStudentByManager(
        role: 'student',
        phoneNumber: _phoneController.text,
        iin: _iinController.text,
        fullName: _nameController.text,
        password: _passwordController.text,
        dateOfBirth: _dateOfBirth!,
        groupId: _selectedGroupId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Аккаунт создан'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
