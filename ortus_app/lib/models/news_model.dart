class NewsModel {
  final String id;
  final String title;
  final String content;
  final String newsType;
  final String category;
  final List<String> images;
  final List<String> targetGroupIds;
  final List<String> targetGroupNames;
  final String authorId;
  final String authorName;
  final String authorType;
  final bool isPinned;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.newsType,
    required this.category,
    required this.images,
    required this.targetGroupIds,
    required this.targetGroupNames,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.isPinned,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final targetGroups = json['targetGroups'] as List? ?? [];

    return NewsModel(
      id: json['_id'],
      title: json['title'],
      content: json['content'],
      newsType: json['newsType']?.toString() ?? 'group',
      category: json['category'],
      images: List<String>.from(json['images'] ?? []),
      targetGroupIds: targetGroups
          .map((g) => g is String ? g : g['_id'] as String)
          .toList(),
      targetGroupNames: targetGroups
          .where((g) => g is Map)
          .map((g) => g['name'] as String)
          .toList(),
      authorId: json['authorId'] is String
          ? json['authorId']
          : json['authorId']['_id'],
      authorName: json['authorId'] is String
          ? ''
          : json['authorId']['fullName'],
      authorType: json['authorId'] is String
          ? ''
          : (json['authorId']['userType'] as List).join(', '),
      isPinned: json['isPinned'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'newsType': newsType,
      'category': category,
      'images': images,
      'targetGroups': targetGroupIds,
      'isPinned': isPinned,
    };
  }

  String get categoryText {
    switch (category) {
      case 'general':
        return 'Общее';
      case 'tournament':
        return 'Турнир';
      case 'event':
        return 'Мероприятие';
      case 'announcement':
        return 'Объявление';
      default:
        return category;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  bool get isForAllGroups => targetGroupIds.isEmpty;
}
