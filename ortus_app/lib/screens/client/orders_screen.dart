import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _ordersFuture = OrderService().getMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: AppColors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('Заказов пока нет'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _OrderCard(order: orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt);
    final itemsText = order.items
        .take(2)
        .map((e) => '${e.name} x${e.quantity}')
        .join(', ');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusChip(status: order.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(date, style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 8),
              Text(
                itemsText.isEmpty ? 'Товаров: ${order.items.length}' : itemsText,
              ),
              const SizedBox(height: 8),
              Text(
                'Сумма: ${order.totalAmount.toStringAsFixed(0)} ₸',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (order.clientComment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ваш комментарий: ${order.clientComment}',
                  style: TextStyle(color: AppColors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusChip(status: order.statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              ...order.items.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('Размер: ${item.size} • ${item.quantity} шт.'),
                    trailing: Text(
                      '${(item.price * item.quantity).toStringAsFixed(0)} ₸',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
              const Divider(),
              Text(
                'Итого: ${order.totalAmount.toStringAsFixed(0)} ₸',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (order.clientComment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Ваш комментарий: ${order.clientComment}'),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    if (status == 'Оплачен') color = Colors.green;
    if (status == 'Доставляется') color = Colors.orange;
    if (status == 'Завершён') color = Colors.black;
    if (status == 'Отменён') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
