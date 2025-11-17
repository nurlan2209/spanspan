import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CreatePaymentScreen extends StatefulWidget {
  const CreatePaymentScreen({super.key});

  @override
  State<CreatePaymentScreen> createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends State<CreatePaymentScreen> {
  String? _selectedGroupId;
  String? _selectedStudentId;
  final _amountController = TextEditingController(text: '20000');
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Создать платёж',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Группа',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<GroupModel>>(
              future: GroupService().getAllGroups(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: snapshot.data!.map((group) {
                    return DropdownMenuItem(
                      value: group.id,
                      child: Text('${group.name} (${group.trainerName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedGroupId = val;
                      _selectedStudentId = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Студент',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedGroupId != null)
              FutureBuilder<List<GroupModel>>(
                future: GroupService().getAllGroups(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  // В реальности нужен отдельный API для получения учеников группы
                  // Пока используем заглушку
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Выберите ученика',
                    ),
                    items: const [],
                    onChanged: (val) =>
                        setState(() => _selectedStudentId = val),
                  );
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Сначала выберите группу'),
              ),
            const SizedBox(height: 20),
            const Text(
              'Месяц',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(months[index]),
                );
              }),
              onChanged: (val) => setState(() => _selectedMonth = val!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Год',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: List.generate(3, (index) {
                final year = DateTime.now().year - 1 + index;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) => setState(() => _selectedYear = val!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Сумма (₸)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : CustomButton(
                      text: 'Создать платёж',
                      onPressed: _createPayment,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _createPayment() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите ученика')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await PaymentService().createPayment(
      studentId: _selectedStudentId!,
      amount: double.parse(_amountController.text),
      month: _selectedMonth,
      year: _selectedYear,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Платёж создан'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка создания платежа')));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
