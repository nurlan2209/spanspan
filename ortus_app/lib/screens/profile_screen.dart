import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary,
            child: Text(
              user.fullName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 48,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            user.fullName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          // ✅ ИСПРАВЛЕНО: показываем все роли
          Wrap(
            spacing: 8,
            children: user.userType.map((role) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRoleColor(role),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRoleLabel(role),
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 30),
          _buildInfoCard([
            _buildInfoRow(Icons.phone, 'Телефон', user.phoneNumber),
            _buildInfoRow(Icons.credit_card, 'ИИН', user.iin),
            _buildInfoRow(
              Icons.cake,
              'Дата рождения',
              user.dateOfBirth.toLocal().toString().split(' ')[0],
            ),
            _buildInfoRow(
              Icons.fitness_center,
              'Вес',
              '${user.weight.toStringAsFixed(1)} кг',
            ),
            if (user.groupId != null)
              _buildInfoRow(Icons.group, 'Группа', user.groupId!),
          ]),
          SizedBox(height: 20),
          CustomButton(
            text: 'Редактировать',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          if (user.isStudent || user.isParent)
            CustomButton(
              text: 'Посещаемость',
              onPressed: () {
                Navigator.pushNamed(context, '/attendance-analytics');
              },
              color: Colors.blue,
            ),
          SizedBox(height: 12),
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
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          SizedBox(width: 8),
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
