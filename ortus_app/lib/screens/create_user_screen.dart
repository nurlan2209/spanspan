// lib/screens/create_user_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../utils/date_picker_helper.dart';
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
  String _selectedRole = 'trainer';
  bool _isLoading = false;

  final roles = const {
    'trainer': 'Тренер',
    'manager': 'Менеджер',
    'tech_staff': 'Техничка',
    'admin': 'Администратор',
  };

  InputDecoration _outlinedField(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

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
        phoneNumber: _phoneController.text.trim(),
        iin: _iinController.text.trim(),
        fullName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        userType: _selectedRole,
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пользователь создан')));
      _phoneController.clear();
      _iinController.clear();
      _nameController.clear();
      _passwordController.clear();
      setState(() => _dateOfBirth = null);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Ошибка создания' : msg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: _outlinedField('Роль'),
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
                  decoration: _outlinedField('Телефон'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iinController,
                  decoration: _outlinedField('ИИН'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.length != 12 ? 'ИИН 12 цифр' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: _outlinedField('ФИО'),
                  validator: (v) => v!.isEmpty ? 'Введите ФИО' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _outlinedField('Пароль'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Минимум 6 символов' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Дата рождения: ${_dateOfBirth?.toLocal().toString().split(' ')[0] ?? 'Не выбрана'}',
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showAppDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _dateOfBirth = date);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    surfaceTintColor: Colors.transparent,
                    side: const BorderSide(color: AppColors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Выбрать дату'),
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
