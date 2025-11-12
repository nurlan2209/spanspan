class CleaningReportModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime date;
  final List<String> zones;
  final List<String> photos;
  final String? comment;

  CleaningReportModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.zones,
    required this.photos,
    this.comment,
  });

  factory CleaningReportModel.fromJson(Map<String, dynamic> json) {
    final staff = json['staffId'];
    return CleaningReportModel(
      id: json['_id']?.toString() ?? '',
      staffId: staff is Map
          ? staff['_id']?.toString() ?? ''
          : staff?.toString() ?? '',
      staffName: staff is Map ? staff['fullName']?.toString() ?? '' : '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      zones: List<String>.from(json['zones']?.map((e) => e.toString()) ?? []),
      photos: List<String>.from(json['photos']?.map((e) => e.toString()) ?? []),
      comment: json['comment']?.toString(),
    );
  }
}
