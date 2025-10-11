import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_model.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';
import '../utils/constants.dart';
import 'create_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<PaymentModel>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  void _loadPayments() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() {
      if (user.isAdmin || user.isTrainer) {
        _paymentsFuture = PaymentService().getUnpaidPayments();
      } else if (user.isStudent) {
        _paymentsFuture = PaymentService().getStudentPayments(user.id);
      } else if (user.isParent &&
          user.children != null &&
          user.children!.isNotEmpty) {
        _paymentsFuture = PaymentService().getStudentPayments(
          user.children![0].id,
        );
      } else {
        _paymentsFuture = Future.value([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Оплата', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          if (user?.isAdmin == true || user?.isTrainer == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePaymentScreen(),
                  ),
                ).then((_) => _loadPayments());
              },
            ),
        ],
      ),
      body: FutureBuilder<List<PaymentModel>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 80, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Нет платежей',
                    style: TextStyle(fontSize: 18, color: AppColors.grey),
                  ),
                ],
              ),
            );
          }

          final payments = snapshot.data!;
          final unpaid = payments.where((p) => p.isUnpaid).toList();
          final paid = payments.where((p) => p.isPaid).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (unpaid.isNotEmpty) ...[
                const Text(
                  'Требуют оплаты',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...unpaid.map((payment) => _buildPaymentCard(payment, user)),
                const SizedBox(height: 24),
              ],
              if (paid.isNotEmpty) ...[
                const Text(
                  'Оплачено',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...paid.map((payment) => _buildPaymentCard(payment, user)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.isAdmin == true || user?.isTrainer == true)
                        Text(
                          payment.studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        payment.periodText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.groupName,
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: payment.isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payment.isPaid ? 'Оплачено' : 'Не оплачено',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сумма',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.amount.toStringAsFixed(0)} ₸',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (payment.isUnpaid &&
                    (user?.isAdmin == true || user?.isTrainer == true))
                  ElevatedButton(
                    onPressed: () => _markAsPaid(payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Отметить оплаченным',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
              ],
            ),
            if (payment.isPaid && payment.paidAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Оплачено: ${payment.paidAt!.day}.${payment.paidAt!.month}.${payment.paidAt!.year}',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markAsPaid(PaymentModel payment) async {
    final success = await PaymentService().markAsPaid(payment.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Платёж отмечен как оплаченный'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPayments();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка обновления платежа')),
      );
    }
  }
}
