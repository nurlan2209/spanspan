import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_model.dart';
import 'auth_service.dart';

class PaymentService {
  Future<bool> createPayment({
    required String studentId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'studentId': studentId,
        'amount': amount,
        'month': month,
        'year': year,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<PaymentModel>> getStudentPayments(String studentId) async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/student/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => PaymentModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<PaymentModel>> getGroupPayments(String groupId) async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/group/$groupId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => PaymentModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<PaymentModel>> getUnpaidPayments() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/unpaid'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => PaymentModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> markAsPaid(String paymentId, {String? paymentMethod}) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/payments/$paymentId/mark-paid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'paymentMethod': paymentMethod ?? 'manual'}),
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getPaymentStats({int? month, int? year}) async {
    final token = await AuthService().getToken();
    String url = '${ApiConfig.baseUrl}/payments/stats';

    if (month != null || year != null) {
      url += '?';
      if (month != null) url += 'month=$month&';
      if (year != null) url += 'year=$year';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
