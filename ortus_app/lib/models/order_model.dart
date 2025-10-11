class OrderItem {
  final String productId;
  final String name;
  final double price;
  final String size;
  final int quantity;
  final String? image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.size,
    required this.quantity,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      name: json['name'],
      price: json['price'].toDouble(),
      size: json['size'],
      quantity: json['quantity'],
      image: json['image'],
    );
  }

  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'],
      userId: json['userId'] is String ? json['userId'] : json['userId']['_id'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Ожидает оплаты';
      case 'paid':
        return 'Оплачен';
      case 'ready':
        return 'Готов к выдаче';
      case 'completed':
        return 'Выдан';
      case 'cancelled':
        return 'Отменён';
      default:
        return status;
    }
  }
}
