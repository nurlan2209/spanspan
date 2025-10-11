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
  bool _isLoading = false;

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
        iconTheme: const IconThemeData(color: AppColors.white),
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
                    value: _userType == 'student',
                    onChanged: (value) {
                      setState(() {
                        _userType = value ? 'student' : 'trainer';
                        _selectedGroupId =
                            null; // Сбрасываем группу при смене роли
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text('Тренер', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Номер телефона'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Введите номер' : null,
              ),
              TextFormField(
                controller: _iinController,
                decoration: const InputDecoration(labelText: 'ИИН'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.length != 12
                    ? 'ИИН должен состоять из 12 цифр'
                    : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО'),
                validator: (value) => value!.isEmpty ? 'Введите ФИО' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Пароль минимум 6 символов' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(
                  _dateOfBirth == null
                      ? 'Дата рождения'
                      : "${_dateOfBirth!.toLocal()}".split(' ')[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dateOfBirth = picked);
                },
              ),
              const SizedBox(height: 10),
              Text('Вес: ${_weight.toStringAsFixed(1)} кг'),
              Slider(
                value: _weight,
                min: 20,
                max: 150,
                divisions: 130,
                label: _weight.toStringAsFixed(1),
                onChanged: (value) => setState(() => _weight = value),
                activeColor: AppColors.primary,
              ),
              if (_userType == 'student')
                FutureBuilder<List<GroupModel>>(
                  future: GroupService().getAllGroups(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      hint: const Text('Выберите группу (необязательно)'),
                      onChanged: (value) =>
                          setState(() => _selectedGroupId = value),
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
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
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
                onPressed: () => Navigator.pushNamed(context, '/login'),
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

  // --- ЭТО ИСПРАВЛЕННЫЙ МЕТОД ---
  void _register() async {
    if (_formKey.currentState!.validate() && _dateOfBirth != null) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Получаем полный ответ (Map) от провайдера
      final result = await authProvider.register({
        'phoneNumber': _phoneController.text,
        'iin': _iinController.text,
        'fullName': _nameController.text,
        'password': _passwordController.text,
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'weight': _weight,
        'userType': _userType,
        'groupId': _selectedGroupId,
      });

      setState(() => _isLoading = false);

      // 2. Проверяем ключ 'success' в ответе
      if (result['success'] == true && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        // 3. Показываем конкретную ошибку с сервера
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Произошла неизвестная ошибка.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_dateOfBirth == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату рождения'),
          backgroundColor: Colors.orange,
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
