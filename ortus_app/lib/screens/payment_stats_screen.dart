import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../utils/constants.dart';

class PaymentStatsScreen extends StatefulWidget {
  const PaymentStatsScreen({super.key});

  @override
  State<PaymentStatsScreen> createState() => _PaymentStatsScreenState();
}

class _PaymentStatsScreenState extends State<PaymentStatsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late Future<Map<String, dynamic>?> _statsFuture;

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
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = PaymentService().getPaymentStats(
        month: _selectedMonth,
        year: _selectedYear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Статистика платежей',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('Нет данных'));
                }

                final stats = snapshot.data!;
                return _buildStatsCards(stats);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Месяц',
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
              onChanged: (val) {
                setState(() => _selectedMonth = val!);
                _loadStats();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: InputDecoration(
                labelText: 'Год',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: List.generate(3, (index) {
                final year = DateTime.now().year - 1 + index;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (val) {
                setState(() => _selectedYear = val!);
                _loadStats();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Всего платежей',
          '${stats['total']}',
          Icons.receipt_long,
          AppColors.primary,
        ),
        _buildStatCard(
          'Оплачено',
          '${stats['paid']}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Не оплачено',
          '${stats['unpaid']}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Общая сумма',
          '${stats['totalAmount'].toStringAsFixed(0)} ₸',
          Icons.payments,
          AppColors.black,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
