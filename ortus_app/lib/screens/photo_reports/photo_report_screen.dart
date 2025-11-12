import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/photo_report_service.dart';
import '../../utils/constants.dart';

class PhotoReportScreen extends StatefulWidget {
  const PhotoReportScreen({super.key});

  @override
  State<PhotoReportScreen> createState() => _PhotoReportScreenState();
}

class _PhotoReportScreenState extends State<PhotoReportScreen> {
  final _commentController = TextEditingController();
  final _relatedController = TextEditingController();
  final _picker = ImagePicker();
  final _service = PhotoReportService();

  String _selectedType = 'training_before';
  bool _isSubmitting = false;
  List<XFile> _images = [];

  final _types = const {
    'training_before': 'Фото ДО тренировки',
    'training_after': 'Фото ПОСЛЕ тренировки',
    'cleaning': 'Уборка (для техничек)',
  };

  Future<void> _pickImages() async {
    try {
      final result = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (result.isEmpty) return;
      setState(() {
        _images = result.take(10).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка выбора фото: $e')));
    }
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одно фото'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!kIsWeb && _images.any((image) => image.path.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный путь к файлу'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final files = _images
          .map((xfile) => File(xfile.path))
          .where((file) => file.path.isNotEmpty)
          .toList();

      final success = await _service.createPhotoReport(
        type: _selectedType,
        relatedId: _relatedController.text.trim().isEmpty
            ? null
            : _relatedController.text.trim(),
        comment: _commentController.text.trim(),
        photos: files,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _images = [];
          _commentController.clear();
          _relatedController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фотоотчёт отправлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось отправить отчёт'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isTrainer = user?.isTrainer ?? false;
    final isTechStaff = user?.hasRole('tech_staff') ?? false;

    final allowedTypes = _types.entries.where((entry) {
      if (entry.key == 'cleaning') {
        return isTechStaff ||
            user?.isAdmin == true ||
            user?.hasRole('director') == true;
      }
      return isTrainer ||
          user?.isAdmin == true ||
          user?.hasRole('director') == true;
    }).toList();

    if (allowedTypes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Фотоотчёт'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Нет доступа к фотоотчётам')),
      );
    }

    if (!allowedTypes.any((entry) => entry.key == _selectedType)) {
      _selectedType = allowedTypes.first.key;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Фотоотчёт',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тип отчёта',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in allowedTypes)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedType == entry.key,
                    onSelected: (_) =>
                        setState(() => _selectedType = entry.key),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _selectedType == entry.key
                          ? AppColors.primary
                          : AppColors.black,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedType.startsWith('training')) _buildRelatedInput(),
            if (_selectedType == 'cleaning')
              TextFormField(
                controller: _relatedController,
                decoration: const InputDecoration(
                  labelText: 'ID отчёта по уборке (опционально)',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoSection(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isSubmitting ? 'Отправка...' : 'Отправить отчёт'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                onPressed: _isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _relatedController,
          decoration: const InputDecoration(
            labelText: 'ID тренировки (расписание)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Укажите ID расписания тренировки, если нужно привязать отчёт.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Фото',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Фото не добавлены')),
          )
        else
          GridView.builder(
            itemCount: _images.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final image = _images[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover)
                        : Image.file(File(image.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => setState(() {
                        _images.removeAt(index);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _relatedController.dispose();
    super.dispose();
  }
}
