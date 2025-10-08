import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _weightController = TextEditingController(
      text: user?.weight.toString() ?? '50',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(
          'Редактировать профиль',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вес (кг)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                ),
              ),
            ),
            Spacer(),
            Center(
              child: _isLoading
                  ? CircularProgressIndicator(color: AppColors.primary)
                  : CustomButton(text: 'Сохранить', onPressed: _updateProfile),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);

    final success = await UserService().updateProfile({
      'weight': double.parse(_weightController.text),
    });

    setState(() => _isLoading = false);

    if (success) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Профиль обновлён'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
