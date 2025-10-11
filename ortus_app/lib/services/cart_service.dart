import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cart_model.dart';
import 'auth_service.dart';

class CartService {
  Future<CartModel?> getCart() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return CartModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> addToCart(String productId, String size, int quantity) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productId': productId,
        'size': size,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateCartItem(
    String productId,
    String size,
    int quantity,
  ) async {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/cart/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productId': productId,
        'size': size,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> removeFromCart(String productId, String size) async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cart/remove'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'productId': productId, 'size': size}),
    );

    return response.statusCode == 200;
  }

  Future<bool> clearCart() async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cart/clear'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
