import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';

class OrderService {
  Future<OrderModel?> createOrder({String? comment}) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse(ApiConfig.ordersUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'comment': comment ?? ''}),
    );

    if (response.statusCode == 201) {
      return OrderModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<List<OrderModel>> getMyOrders() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.ordersUrl}/my'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<OrderModel>> getAllOrders({String? status}) async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    String url = ApiConfig.ordersUrl;
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<OrderModel?> updateOrderStatus({
    required String orderId,
    required String status,
    String? managerNote,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final response = await http.patch(
      Uri.parse('${ApiConfig.ordersUrl}/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status, 'managerNote': managerNote}),
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(json.decode(response.body));
    }
    return null;
  }
}
