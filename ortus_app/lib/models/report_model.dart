class ReportAttachment {
  final String url;
  final String fileType;
  final String originalName;

  ReportAttachment({
    required this.url,
    required this.fileType,
    required this.originalName,
  });

  factory ReportAttachment.fromJson(Map<String, dynamic> json) {
    return ReportAttachment(
      url: json['url']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
    );
  }
}

class ReportModel {
  final String id;
  final String trainerName;
  final String trainerPhone;
  final DateTime trainingDate;
  final String slot;
  final String comment;
  final bool isLate;
  final List<ReportAttachment> attachments;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.trainerName,
    required this.trainerPhone,
    required this.trainingDate,
    required this.slot,
    required this.comment,
    required this.isLate,
    required this.attachments,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainerId'];
    final attachments = (json['attachments'] as List? ?? [])
        .map((e) => ReportAttachment.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReportModel(
      id: json['_id']?.toString() ?? '',
      trainerName:
          trainer is Map ? trainer['fullName']?.toString() ?? '' : '',
      trainerPhone:
          trainer is Map ? trainer['phoneNumber']?.toString() ?? '' : '',
      trainingDate:
          DateTime.tryParse(json['trainingDate']?.toString() ?? '') ??
              DateTime.now(),
      slot: json['slot']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      isLate: json['isLate'] == true,
      attachments: attachments,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
