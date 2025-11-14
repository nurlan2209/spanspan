import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cleaning_report_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_picker_helper.dart';

class CleaningReportScreen extends StatefulWidget {
  const CleaningReportScreen({super.key});

  @override
  State<CleaningReportScreen> createState() => _CleaningReportScreenState();
}

class _CleaningReportScreenState extends State<CleaningReportScreen> {
  final _commentController = TextEditingController();
  final _service = CleaningReportService();
  final _picker = ImagePicker();

  DateTime _selectedDateTime = DateTime.now();
  final List<String> _zones = ['hall', 'locker_room', 'shower', 'corridor'];
  final Set<String> _selectedZones = {'hall'};
  List<XFile> _photos = [];
  bool _isSubmitting = false;

  Future<void> _pickPhotos() async {
    try {
      final result = await _picker.pickMultiImage(imageQuality: 85);
      setState(() {
        _photos = result.take(5).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка выбора фото: $e')));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      final time = TimeOfDay.fromDateTime(_selectedDateTime);
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedZones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одну зону'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте фото уборки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final files = _photos.map((xfile) => File(xfile.path)).toList();
      final success = await _service.createReport(
        date: _selectedDateTime,
        zones: _selectedZones.toList(),
        comment: _commentController.text.trim(),
        photos: files,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _photos = [];
          _commentController.clear();
          _selectedZones
            ..clear()
            ..add('hall');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отчёт об уборке отправлен'),
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
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isTechStaff = user?.hasRole('tech_staff') ?? false;

    if (!isTechStaff &&
        user?.isAdmin != true &&
        user?.hasRole('director') != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Отчёт уборки'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Доступно только техничкам')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Отчёт об уборке',
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
              'Дата и время',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${_selectedDateTime.day.toString().padLeft(2, '0')}.'
                      '${_selectedDateTime.month.toString().padLeft(2, '0')}.'
                      '${_selectedDateTime.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      '${_selectedDateTime.hour.toString().padLeft(2, '0')}:'
                      '${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Зоны уборки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _zones
                  .map(
                    (zone) => FilterChip(
                      label: Text(_zoneLabel(zone)),
                      selected: _selectedZones.contains(zone),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedZones.add(zone);
                          } else {
                            _selectedZones.remove(zone);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фото (до 5 шт.)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_photos.isEmpty)
              Container(
                height: 140,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.grey.withOpacity(0.1),
                ),
                child: const Text('Фото не добавлены'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(photo.path, fit: BoxFit.cover)
                            : Image.file(File(photo.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(index)),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text('Отправить отчёт'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _zoneLabel(String zone) {
    switch (zone) {
      case 'hall':
        return 'Зал';
      case 'locker_room':
        return 'Раздевалка';
      case 'shower':
        return 'Душевая';
      case 'corridor':
        return 'Коридор';
      default:
        return zone;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
