class CartItemModel {
  final String productId;
  final String name;
  final String image;
  final String size;
  final int quantity;
  final double price;
  final double totalPrice;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.size,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CartModel {
  final List<CartItemModel> items;
  final double totalAmount;

  CartModel({required this.items, required this.totalAmount});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CartModel(
      items: items,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isEmpty => items.isEmpty;
}
