import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user),
            const SizedBox(height: 24),
            const Text(
              'Контакты',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.phone, 'Телефон', user.phoneNumber),
              _buildInfoRow(Icons.credit_card, 'ИИН', user.iin),
              _buildInfoRow(
                Icons.cake,
                'Дата рождения',
                user.dateOfBirth.toLocal().toString().split(' ')[0],
              ),
              if (user.groupId != null)
                _buildInfoRow(Icons.group, 'Группа', user.groupId!),
            ]),
            const SizedBox(height: 24),
            const Text(
              'Действия',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (user.isStudent)
                      CustomButton(
                        text: 'Мои заказы',
                        onPressed: () {
                          Navigator.pushNamed(context, '/my-orders');
                        },
                        color: Colors.blue,
                      ),
                    if (user.isStudent) const SizedBox(height: 12),
                    if (user.isTrainer) ...[
                      CustomButton(
                        text: 'Новости клуба',
                        onPressed: () {
                          Navigator.pushNamed(context, '/news');
                        },
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomButton(
                      text: 'Выйти',
                      onPressed: () {
                        authProvider.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primary,
            child: Text(
              user.fullName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 42,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: user.userType.map((role) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRoleColor(role),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRoleLabel(role),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ ДОБАВЛЕНО: метод для определения цвета роли
  Color _getRoleColor(String role) {
    switch (role) {
      case 'director':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'trainer':
        return Colors.orange;
      case 'manager':
        return Colors.blueAccent;
      case 'tech_staff':
        return Colors.brown;
      case 'student':
        return AppColors.primary;
      case 'parent':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ ДОБАВЛЕНО: метод для текста роли
  String _getRoleLabel(String role) {
    switch (role) {
      case 'director':
        return 'Директор';
      case 'admin':
        return 'Администратор';
      case 'trainer':
        return 'Тренер';
      case 'manager':
        return 'Менеджер';
      case 'tech_staff':
        return 'Техничка';
      case 'student':
        return 'Ученик';
      case 'parent':
        return 'Родитель';
      default:
        return role;
    }
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
