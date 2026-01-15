import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/cart_service.dart';
import '../../utils/constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товар'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGallery(product),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${product.price.toStringAsFixed(0)} ₸',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.description.isEmpty
                ? 'Описание скоро появится'
                : product.description,
            style: TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Размер',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: product.sizes.map((size) {
              final isSelected = _selectedSize == size.label;
              final isAvailable = size.stock > 0;
              return ChoiceChip(
                label: Text('${size.label} (${size.stock})'),
                selected: isSelected,
                onSelected: isAvailable
                    ? (_) => setState(() {
                          _selectedSize = size.label;
                          _quantity = 1;
                        })
                    : null,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.white
                      : isAvailable
                          ? AppColors.black
                          : AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSize != null) ...[
            const SizedBox(height: 20),
            _buildQuantitySelector(product),
          ],
          const SizedBox(height: 24),
          _isAdding
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedSize == null ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Добавить в корзину',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGallery(ProductModel product) {
    if (product.images.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: AppColors.grey),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              product.images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.white,
                child: const Center(
                  child: Icon(Icons.broken_image, color: AppColors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantitySelector(ProductModel product) {
    final selected =
        product.sizes.firstWhere((size) => size.label == _selectedSize);
    final maxQty = selected.stock;

    return Row(
      children: [
        const Text(
          'Количество',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$_quantity',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed:
              _quantity < maxQty ? () => setState(() => _quantity++) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Future<void> _addToCart() async {
    if (_selectedSize == null) return;

    setState(() => _isAdding = true);
    final cart = await CartService()
        .addToCart(widget.product.id, _selectedSize!, _quantity);
    setState(() => _isAdding = false);

    if (!mounted) return;
    if (cart != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавлено в корзину'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось добавить в корзину')),
      );
    }
  }
}
