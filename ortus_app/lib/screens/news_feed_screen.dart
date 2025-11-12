import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../providers/auth_provider.dart';
import '../services/news_service.dart';
import '../utils/constants.dart';
import 'news_detail_screen.dart';
import 'create_news_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String? _selectedCategory;
  String _selectedType = 'all';
  late Future<List<NewsModel>> _newsFuture;

  final categories = {
    null: 'Все',
    'general': 'Общее',
    'tournament': 'Турниры',
    'event': 'Мероприятия',
    'announcement': 'Объявления',
  };

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    setState(() {
      _newsFuture = NewsService().getAllNews(
        category: _selectedCategory,
        groupId: user?.groupId,
        type: _selectedType == 'all' ? null : _selectedType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final canCreateNews =
        user?.isAdmin == true ||
        user?.isTrainer == true ||
        user?.hasRole('manager') == true ||
        user?.hasRole('director') == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Новости', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          if (canCreateNews)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateNewsScreen(),
                  ),
                ).then((_) => _loadNews());
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          const SizedBox(height: 8),
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<List<NewsModel>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 80, color: AppColors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Нет новостей',
                          style: TextStyle(fontSize: 18, color: AppColors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final news = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => _loadNews(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: news.length,
                    itemBuilder: (context, index) {
                      return _buildNewsCard(news[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = entry.key;
                  _loadNews();
                });
              },
              backgroundColor: AppColors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilter() {
    const types = {'all': 'Все', 'group': 'Групповые', 'general': 'Общие'};

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final key = types.keys.elementAt(index);
          final label = types[key]!;
          final isSelected = _selectedType == key;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedType = key;
                _loadNews();
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: types.length,
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(newsId: news.id),
          ),
        ).then((_) => _loadNews());
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  news.images[0],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: AppColors.grey.withOpacity(0.2),
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (news.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 12,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Закреплено',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (news.isPinned) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(news.category),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news.categoryText,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          news.newsType == 'general' ? 'Общая' : 'Групповая',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                      ),
                      const Spacer(),
                      Text(
                        news.timeAgo,
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.content,
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          news.authorName.isNotEmpty
                              ? news.authorName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        news.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (news.targetGroupNames.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            news.targetGroupNames.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}
