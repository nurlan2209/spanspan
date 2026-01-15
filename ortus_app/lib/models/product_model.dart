class ProductSize {
  final String label;
  final int stock;

  const ProductSize({required this.label, required this.stock});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      label: json['label']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'stock': stock,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> images;
  final List<ProductSize> sizes;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.images,
    required this.sizes,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final sizes = (json['sizes'] as List? ?? [])
        .map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      sizes: sizes,
    );
  }
}
