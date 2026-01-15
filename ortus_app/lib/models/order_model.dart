class OrderItemModel {
  final String name;
  final String image;
  final String size;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.name,
    required this.image,
    required this.size,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status;
  final String clientComment;
  final String managerNote;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.clientComment,
    required this.managerNote,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      clientPhone: json['clientPhone']?.toString() ?? '',
      items: items,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'new',
      clientComment: json['clientComment']?.toString() ?? '',
      managerNote: json['managerNote']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'contacted':
        return 'Связались';
      case 'paid':
        return 'Оплачен';
      case 'delivering':
        return 'Доставляется';
      case 'completed':
        return 'Завершён';
      case 'canceled':
        return 'Отменён';
      default:
        return status;
    }
  }
}
