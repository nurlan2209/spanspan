import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(
          widget.product.name,
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.product.price.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Описание',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildSizeSelector(),
                  const SizedBox(height: 24),
                  _buildQuantitySelector(),
                  const SizedBox(height: 32),
                  Center(
                    child: CustomButton(
                      text: 'Добавить в корзину',
                      onPressed: _addToCart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Container(
      height: 300,
      width: double.infinity,
      color: AppColors.grey.withOpacity(0.1),
      child: widget.product.images.isNotEmpty
          ? Image.network(
              widget.product.images[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.image_not_supported, size: 100),
                );
              },
            )
          : const Center(child: Icon(Icons.shopping_bag, size: 100)),
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Размер',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: widget.product.sizes.map((sizeData) {
            final isSelected = _selectedSize == sizeData.size;
            final isAvailable = sizeData.stock > 0;

            return ChoiceChip(
              label: Text('${sizeData.size} (${sizeData.stock})'),
              selected: isSelected,
              onSelected: isAvailable
                  ? (selected) {
                      setState(() {
                        _selectedSize = sizeData.size;
                        _quantity = 1;
                      });
                    }
                  : null,
              backgroundColor: isAvailable
                  ? AppColors.white
                  : AppColors.grey.withOpacity(0.3),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.white
                    : (isAvailable ? AppColors.black : AppColors.grey),
                fontWeight: FontWeight.bold,
              ),
              disabledColor: AppColors.grey.withOpacity(0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    final selectedSizeData = _selectedSize != null
        ? widget.product.sizes.firstWhere((s) => s.size == _selectedSize)
        : null;

    final maxQuantity = selectedSizeData?.stock ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Количество',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              color: AppColors.primary,
            ),
            Text(
              '$_quantity',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _quantity < maxQuantity
                  ? () => setState(() => _quantity++)
                  : null,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Доступно: $maxQuantity',
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  void _addToCart() async {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите размер')));
      return;
    }

    final success = await CartService().addToCart(
      widget.product.id,
      _selectedSize!,
      _quantity,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавлено в корзину'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления в корзину')),
      );
    }
  }
}
