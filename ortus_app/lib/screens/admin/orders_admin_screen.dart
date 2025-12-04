import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/delivery_request_model.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';

class OrdersAdminScreen extends StatefulWidget {
  const OrdersAdminScreen({super.key});

  @override
  State<OrdersAdminScreen> createState() => _OrdersAdminScreenState();
}

class _OrdersAdminScreenState extends State<OrdersAdminScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<OrderModel>> _ordersFuture;
  late Future<List<DeliveryRequestModel>> _deliveryFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() {
    setState(() {
      _ordersFuture = OrderService().getAllOrders();
      _deliveryFuture = OrderService().getDeliveryRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Заказы', style: TextStyle(color: AppColors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.white, 
          unselectedLabelColor: AppColors.white,
          tabs: const [
            Tab(text: 'Все заказы'),
            Tab(text: 'Заявки на доставку'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersTab(future: _ordersFuture, onRefresh: _load),
          _DeliveryTab(future: _deliveryFuture, onRefresh: _load),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final Future<List<OrderModel>> future;
  final VoidCallback onRefresh;
  const _OrdersTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<OrderModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Заказов нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderAdminCard(order: order, onRefresh: onRefresh);
            },
          );
        },
      ),
    );
  }
}

class _OrderAdminCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRefresh;
  const _OrderAdminCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt.toLocal();
    final dateText = DateFormat('dd.MM.y HH:mm').format(date);
    final statusMeta = _statusMeta(order.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Заказ ${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(statusMeta.$1),
                    backgroundColor: statusMeta.$2.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: statusMeta.$2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    dateText,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Сумма: ${order.totalAmount.toStringAsFixed(0)} ₸'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ученик: ${order.userId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Способ: ${order.paymentMethod}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusSelector(
                orderId: order.id,
                current: order.status,
                onChanged: onRefresh,
              ),
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
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ ${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle:
                        Text('Размер: ${item.size} • ${item.quantity} шт.'),
                    trailing: Text(
                      '${(item.price * item.quantity).toStringAsFixed(0)} ₸',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Итого: ${order.totalAmount.toStringAsFixed(0)} ₸'),
              ],
            ),
          ),
        );
      },
    );
  }

  (String, Color) _statusMeta(String status) {
    switch (status) {
      case 'new':
        return ('Новый', Colors.blueGrey);
      case 'preparing':
        return ('Готовится', Colors.orange);
      case 'ready':
        return ('Готов к выдаче', Colors.teal);
      case 'issued':
        return ('Выдан', Colors.green);
      case 'cancelled':
        return ('Отменён', Colors.red);
      default:
        return (status, Colors.blueGrey);
    }
  }
}

class _StatusSelector extends StatefulWidget {
  final String orderId;
  final String current;
  final VoidCallback onChanged;
  const _StatusSelector({
    required this.orderId,
    required this.current,
    required this.onChanged,
  });

  @override
  State<_StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<_StatusSelector> {
  bool _loading = false;
  static const statuses = [
    'new',
    'preparing',
    'ready',
    'issued',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Статус:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: statuses.contains(widget.current)
              ? widget.current
              : statuses.first,
          onChanged: _loading
              ? null
              : (val) async {
                  if (val == null || val == widget.current) return;
                  setState(() => _loading = true);
                  final ok = await OrderService()
                      .updateOrderStatus(widget.orderId, val);
                  setState(() => _loading = false);
                  if (ok) {
                    widget.onChanged();
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Не удалось обновить статус'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          items: statuses
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_statusLabel(s)),
                ),
              )
              .toList(),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'preparing':
        return 'Готовится';
      case 'ready':
        return 'Готов к выдаче';
      case 'issued':
        return 'Выдан';
      case 'cancelled':
        return 'Отменён';
      default:
        return status;
    }
  }
}

class _DeliveryTab extends StatelessWidget {
  final Future<List<DeliveryRequestModel>> future;
  final VoidCallback onRefresh;

  const _DeliveryTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<DeliveryRequestModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('Заявок нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = requests[index];
              return _DeliveryCard(request: r, onRefresh: onRefresh);
            },
          );
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryRequestModel request;
  final VoidCallback onRefresh;

  const _DeliveryCard({required this.request, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final created =
        DateFormat('dd.MM.y HH:mm').format(request.createdAt.toLocal());
    final statusMeta = _deliveryMeta(request.status);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _show(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('Заявка ${request.id}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(statusMeta.$1),
                    backgroundColor: statusMeta.$2.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: statusMeta.$2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    created,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Заказ: ${request.orderId}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Ученик: ${request.studentName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Телефон: ${request.phoneNumber}'),
            ],
          ),
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заявка ${request.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Заказ: ${request.orderId}'),
                Text('Ученик: ${request.studentName}'),
                Text('Телефон: ${request.phoneNumber}'),
                Text('Состав: ${request.summary}'),
                Text('Самовывоз: ${request.pickupAddress}'),
                const SizedBox(height: 12),
                _DeliveryStatusSelector(
                  id: request.id,
                  current: request.status,
                  onChanged: onRefresh,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeliveryStatusSelector extends StatefulWidget {
  final String id;
  final String current;
  final VoidCallback onChanged;

  const _DeliveryStatusSelector({
    required this.id,
    required this.current,
    required this.onChanged,
  });

  @override
  State<_DeliveryStatusSelector> createState() =>
      _DeliveryStatusSelectorState();
}

class _DeliveryStatusSelectorState extends State<_DeliveryStatusSelector> {
  bool _loading = false;
  static const statuses = [
    'new',
    'in_progress',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: statuses.contains(widget.current)
          ? widget.current
          : statuses.first,
      items: statuses
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(_statusLabel(s)),
            ),
          )
          .toList(),
      onChanged: _loading
          ? null
          : (val) async {
              if (val == null || val == widget.current) return;
              setState(() => _loading = true);
              final ok =
                  await OrderService().updateDeliveryStatus(widget.id, val);
              setState(() => _loading = false);
              if (ok) {
                widget.onChanged();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не удалось обновить статус заявки'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'Новая';
      case 'in_progress':
        return 'В процессе';
      case 'delivered':
        return 'Доставлена';
      case 'cancelled':
        return 'Отменена';
      default:
        return status;
    }
  }

}

(String, Color) _deliveryMeta(String status) {
  switch (status) {
    case 'new':
      return ('Новая', Colors.blueGrey);
    case 'in_progress':
      return ('В процессе', Colors.orange);
    case 'delivered':
      return ('Доставлена', Colors.green);
    case 'cancelled':
      return ('Отменена', Colors.red);
    default:
      return (status, Colors.blueGrey);
  }
}
