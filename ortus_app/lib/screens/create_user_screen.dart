// lib/screens/create_user_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _dateOfBirth;
  double _weight = 70.0;
  String _selectedRole = 'trainer';
  bool _isLoading = false;

  final roles = {'trainer': 'Тренер', 'admin': 'Администратор'};

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate() || _dateOfBirth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserService().createUser(
        phoneNumber: _phoneController.text,
        iin: _iinController.text,
        fullName: _nameController.text,
        dateOfBirth: _dateOfBirth!,
        weight: _weight,
        userType: _selectedRole,
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пользователь создан')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                'Роль',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: roles.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iinController,
                decoration: const InputDecoration(labelText: 'ИИН'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 12 ? 'ИИН 12 цифр' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО'),
                validator: (v) => v!.isEmpty ? 'Введите ФИО' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Минимум 6 символов' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Дата рождения: ${_dateOfBirth?.toLocal().toString().split(' ')[0] ?? 'Не выбрана'}',
              ),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
                child: const Text('Выбрать дату'),
              ),
              const SizedBox(height: 16),
              Text('Вес: ${_weight.toStringAsFixed(0)} кг'),
              Slider(
                value: _weight,
                min: 30,
                max: 150,
                onChanged: (v) => setState(() => _weight = v),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                CustomButton(text: 'Создать', onPressed: _createUser),
            ],
          ),
        ),
      ),
    );
  }
}
