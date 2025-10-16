// lib/widgets/stock_management_modal.dart (исправить)
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';

class StockManagementModal extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onUpdated;

  const StockManagementModal({
    super.key,
    required this.product,
    required this.onUpdated,
  });

  @override
  State<StockManagementModal> createState() => _StockManagementModalState();
}

class _StockManagementModalState extends State<StockManagementModal> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var size in _sizes) {
      // ✅ ИСПРАВЛЕНО: правильная работа с ProductSize
      final existingSize = widget.product.sizes.firstWhere(
        (s) => s.size == size,
        orElse: () => ProductSize(size: size, stock: 0),
      );
      _controllers[size] = TextEditingController(
        text: existingSize.stock.toString(),
      );
    }
  }

  Future<void> _updateStock() async {
    setState(() => _isLoading = true);

    try {
      for (var size in _sizes) {
        final stock = int.tryParse(_controllers[size]!.text) ?? 0;
        await ProductService().updateStock(widget.product.id, size, stock);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Остатки обновлены')));
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Управление остатками',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.product.name,
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Укажите количество для каждого размера:',
              style: TextStyle(fontSize: 14, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            // ✅ ИСПРАВЛЕНО: убрал toList()
            ..._sizes.map((size) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        size,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controllers[size],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Количество',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Сохранить',
                        style: TextStyle(fontSize: 16, color: AppColors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
