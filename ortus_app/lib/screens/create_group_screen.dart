import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text('Создать группу', style: TextStyle(color: AppColors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Название группы (например, 2024-3)',
              icon: Icons.group,
            ),
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator(color: AppColors.primary)
                : CustomButton(text: 'Создать', onPressed: _createGroup),
          ],
        ),
      ),
    );
  }

  void _createGroup() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.groupsUrl}/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'name': _nameController.text}),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Группа создана!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания группы')));
    }
  }
}
