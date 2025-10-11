import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../models/group_model.dart';
import '../services/news_service.dart';
import '../services/group_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class CreateNewsScreen extends StatefulWidget {
  final NewsModel? news;

  const CreateNewsScreen({super.key, this.news});

  @override
  State<CreateNewsScreen> createState() => _CreateNewsScreenState();
}

class _CreateNewsScreenState extends State<CreateNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'general';
  List<String> _selectedGroupIds = [];
  List<String> _imageUrls = [];
  bool _isPinned = false;
  bool _isLoading = false;

  final categories = {
    'general': 'Общее',
    'tournament': 'Турнир',
    'event': 'Мероприятие',
    'announcement': 'Объявление',
  };

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      _titleController.text = widget.news!.title;
      _contentController.text = widget.news!.content;
      _selectedCategory = widget.news!.category;
      _selectedGroupIds = List.from(widget.news!.targetGroupIds);
      _imageUrls = List.from(widget.news!.images);
      _isPinned = widget.news!.isPinned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.news != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(
          isEdit ? 'Редактировать новость' : 'Создать новость',
          style: const TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildCategorySelector(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Заголовок',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title, color: AppColors.primary),
              ),
              validator: (val) => val!.isEmpty ? 'Введите заголовок' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Содержание',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              validator: (val) => val!.isEmpty ? 'Введите содержание' : null,
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: 20),
            _buildGroupSelector(),
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Закрепить новость'),
              subtitle: const Text('Будет показываться первой'),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : CustomButton(
                    text: isEdit ? 'Сохранить изменения' : 'Опубликовать',
                    onPressed: _submitNews,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категория',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = entry.key);
                }
              },
              backgroundColor: AppColors.white,
              selectedColor: _getCategoryColor(entry.key),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(color: _getCategoryColor(entry.key)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Целевая аудитория',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Оставьте пустым для публикации всем',
          style: TextStyle(fontSize: 12, color: AppColors.grey),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<GroupModel>>(
          future: GroupService().getAllGroups(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final groups = snapshot.data!;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Все группы'),
                    value: _selectedGroupIds.isEmpty,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedGroupIds.clear();
                        }
                      });
                    },
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const Divider(),
                  ...groups.map((group) {
                    final isSelected = _selectedGroupIds.contains(group.id);
                    return CheckboxListTile(
                      title: Text(group.name),
                      subtitle: Text('Тренер: ${group.trainerName}'),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedGroupIds.add(group.id);
                          } else {
                            _selectedGroupIds.remove(group.id);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Изображения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addImageUrl,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Добавить URL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_imageUrls.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.image, size: 48, color: AppColors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Нет изображений',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _imageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.grey.withOpacity(0.2),
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _imageUrls.removeAt(index));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'general':
        return AppColors.primary;
      case 'tournament':
        return Colors.orange;
      case 'event':
        return Colors.blue;
      case 'announcement':
        return Colors.purple;
      default:
        return AppColors.grey;
    }
  }

  void _addImageUrl() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить изображение'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL изображения',
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() => _imageUrls.add(url));
    }
  }

  void _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newsData = {
      'title': _titleController.text,
      'content': _contentController.text,
      'category': _selectedCategory,
      'images': _imageUrls,
      'targetGroups': _selectedGroupIds,
      'isPinned': _isPinned,
    };

    bool success;
    if (widget.news != null) {
      success = await NewsService().updateNews(widget.news!.id, newsData);
    } else {
      final result = await NewsService().createNews(newsData);
      success = result != null;
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.news != null ? 'Новость обновлена' : 'Новость опубликована',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сохранения новости')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
