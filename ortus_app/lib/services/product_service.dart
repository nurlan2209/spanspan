import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'dart:io';

class ProductService {
  Future<List<ProductModel>> getAllProducts({String? category}) async {
    final uri = category != null
        ? Uri.parse('${ApiConfig.baseUrl}/products?category=$category')
        : Uri.parse('${ApiConfig.baseUrl}/products');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<ProductModel?> getProductById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required List<File> images,
  }) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['price'] = price.toString();

    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    final response = await request.send();

    if (response.statusCode != 201) {
      throw Exception('Failed to create product');
    }
  }

  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(productData),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteProduct(String id) async {
    final token = await AuthService().getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<bool> updateStock(String id, String size, int stock) async {
    final token = await AuthService().getToken();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/products/$id/stock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'size': size, 'stock': stock}),
    );

    return response.statusCode == 200;
  }
}
