class ProductSize {
  final String size;
  final int stock;

  ProductSize({required this.size, required this.stock});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(size: json['size'], stock: json['stock']);
  }

  Map<String, dynamic> toJson() {
    return {'size': size, 'stock': stock};
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> images;
  final List<ProductSize> sizes;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.images,
    required this.sizes,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: json['price'].toDouble(),
      images: List<String>.from(json['images'] ?? []),
      sizes: (json['sizes'] as List)
          .map((s) => ProductSize.fromJson(s))
          .toList(),
      isActive: json['isActive'] ?? true,
    );
  }

  int getTotalStock() {
    return sizes.fold(0, (sum, size) => sum + size.stock);
  }

  bool get inStock => getTotalStock() > 0;
}
