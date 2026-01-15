import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ProductService {
  Future<List<ProductModel>> getProducts({String? category}) async {
    String url = ApiConfig.productsUrl;
    if (category != null && category.isNotEmpty) {
      url += '?category=$category';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => ProductModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<ProductModel?> getProduct(String id) async {
    final response =
        await http.get(Uri.parse('${ApiConfig.productsUrl}/$id'));
    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<ProductModel?> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required List<ProductSize> sizes,
    required List<File> images,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.productsUrl),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['price'] = price.toString();
    request.fields['sizes'] = json.encode(
      sizes.map((s) => s.toJson()).toList(),
    );

    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 201) {
      return ProductModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<ProductModel?> updateProduct({
    required String id,
    required String name,
    required String description,
    required String category,
    required double price,
    required List<ProductSize> sizes,
    List<File>? images,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return null;

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.productsUrl}/$id'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['price'] = price.toString();
    request.fields['sizes'] = json.encode(
      sizes.map((s) => s.toJson()).toList(),
    );

    if (images != null) {
      for (final image in images) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          image.path,
        ));
      }
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      return ProductModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> deleteProduct(String id) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${ApiConfig.productsUrl}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
