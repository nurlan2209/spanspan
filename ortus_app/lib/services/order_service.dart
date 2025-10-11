import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';

class OrderService {
  Future<OrderModel?> createOrder({String? paymentMethod}) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'paymentMethod': paymentMethod ?? 'manual'}),
    );

    if (response.statusCode == 201) {
      return OrderModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<List<OrderModel>> getMyOrders() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/my-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<OrderModel>> getAllOrders({String? status}) async {
    final token = await AuthService().getToken();
    final uri = status != null
        ? Uri.parse('${ApiConfig.baseUrl}/orders/all?status=$status')
        : Uri.parse('${ApiConfig.baseUrl}/orders/all');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    return response.statusCode == 200;
  }

  Future<bool> cancelOrder(String orderId) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
