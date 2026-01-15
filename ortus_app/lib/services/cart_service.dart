import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cart_model.dart';
import 'auth_service.dart';

class CartService {
  Future<CartModel?> getCart() async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConfig.cartUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return CartModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<CartModel?> addToCart(
    String productId,
    String size,
    int quantity,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${ApiConfig.cartUrl}/add'),
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

    if (response.statusCode == 200) {
      return CartModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<CartModel?> updateCartItem(
    String productId,
    String size,
    int quantity,
  ) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.put(
      Uri.parse('${ApiConfig.cartUrl}/update'),
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

    if (response.statusCode == 200) {
      return CartModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<CartModel?> removeFromCart(String productId, String size) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.delete(
      Uri.parse('${ApiConfig.cartUrl}/remove'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'productId': productId, 'size': size}),
    );

    if (response.statusCode == 200) {
      return CartModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> clearCart() async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${ApiConfig.cartUrl}/clear'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
