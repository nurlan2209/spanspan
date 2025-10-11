import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final String size;
  int quantity;

  CartItem({required this.product, required this.size, required this.quantity});

  double get totalPrice => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['productId']),
      size: json['size'],
      quantity: json['quantity'],
    );
  }
}

class CartModel {
  final String id;
  final List<CartItem> items;

  CartModel({required this.id, required this.items});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['_id'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;
}
