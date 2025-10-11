import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/logo.png', width: 200, height: 200),
              const SizedBox(height: 40),
              const Text(
                'Вход в систему',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _phoneController,
                label: 'Номер телефона',
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Пароль',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                CustomButton(text: 'Войти', onPressed: _login),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ЭТО ИСПРАВЛЕННЫЙ МЕТОД ---
  void _login() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Получаем полный ответ (Map)
    final result = await authProvider.login(
      _phoneController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    // 2. Проверяем ключ 'success' в ответе
    if (result['success'] == true && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      // 3. Показываем конкретную ошибку с сервера
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Неверные данные'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
