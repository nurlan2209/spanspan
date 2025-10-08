import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import '../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _userType = 'student';
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _dateOfBirth;
  double _weight = 50.0;
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Регистрация',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ученик', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: _userType == 'trainer',
                    onChanged: (val) =>
                        setState(() => _userType = val ? 'trainer' : 'student'),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Тренер', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Номер телефона'),
                validator: (val) => val!.isEmpty ? 'Введите номер' : null,
              ),
              TextFormField(
                controller: _iinController,
                decoration: const InputDecoration(labelText: 'ИИН'),
                maxLength: 12,
                validator: (val) =>
                    val!.length != 12 ? 'ИИН должен быть 12 символов' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО'),
                validator: (val) => val!.isEmpty ? 'Введите ФИО' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Минимум 6 символов' : null,
              ),
              ListTile(
                title: Text(
                  'Дата рождения: ${_dateOfBirth?.toLocal().toString().split(' ')[0] ?? 'Не выбрано'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
              ),
              Text('Вес: ${_weight.toStringAsFixed(1)} кг'),
              Slider(
                value: _weight,
                min: 30,
                max: 150,
                onChanged: (val) => setState(() => _weight = val),
                activeColor: AppColors.primary,
              ),
              if (_userType == 'student') ...[
                const SizedBox(height: 20),
                FutureBuilder<List<GroupModel>>(
                  future: GroupService().getAllGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: AppColors.primary,
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text(
                        'Нет доступных групп',
                        style: TextStyle(color: AppColors.grey),
                      );
                    }
                    final groups = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Выберите группу (опционально)',
                      ),
                      items: groups.map((group) {
                        return DropdownMenuItem(
                          value: group.id,
                          child: Text('${group.name} (${group.trainerName})'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedGroupId = val),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Зарегистрироваться',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Уже есть аккаунт? Войти',
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate() && _dateOfBirth != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register({
        'phoneNumber': _phoneController.text,
        'iin': _iinController.text,
        'fullName': _nameController.text,
        'password': _passwordController.text,
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'weight': _weight,
        'userType': _userType,
        'groupId': _selectedGroupId,
      });

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка регистрации. Проверьте данные.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else if (_dateOfBirth == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату рождения'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _iinController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
