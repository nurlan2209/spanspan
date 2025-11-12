class PhotoReportModel {
  final String id;
  final String type;
  final String authorId;
  final String authorName;
  final List<String> photos;
  final String? comment;
  final DateTime createdAt;

  PhotoReportModel({
    required this.id,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.photos,
    this.comment,
    required this.createdAt,
  });

  factory PhotoReportModel.fromJson(Map<String, dynamic> json) {
    final author = json['authorId'];
    return PhotoReportModel(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      authorId: author is Map
          ? author['_id']?.toString() ?? ''
          : author?.toString() ?? '',
      authorName: author is Map ? author['fullName']?.toString() ?? '' : '',
      photos: List<String>.from(json['photos']?.map((e) => e.toString()) ?? []),
      comment: json['comment']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
