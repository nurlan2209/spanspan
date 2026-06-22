class GroupModel {
  final String id;
  final String title;
  final String description;
  final String trainerId;
  final String? trainerName;
  final DateTime scheduledAt;
  final int maxParticipants;
  final int ageMin;
  final int ageMax;
  final String status;
  final int enrolledCount;
  final bool isEnrolled;

  GroupModel({
    required this.id,
    required this.title,
    required this.description,
    required this.trainerId,
    this.trainerName,
    required this.scheduledAt,
    required this.maxParticipants,
    required this.ageMin,
    required this.ageMax,
    required this.status,
    required this.enrolledCount,
    required this.isEnrolled,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      trainerId: json['trainerId']?.toString() ?? '',
      trainerName: json['trainerName']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
      maxParticipants: json['maxParticipants'] as int? ?? 20,
      ageMin: json['ageMin'] as int? ?? 0,
      ageMax: json['ageMax'] as int? ?? 99,
      status: json['status']?.toString() ?? 'recruiting',
      enrolledCount: json['enrolledCount'] as int? ?? 0,
      isEnrolled: json['isEnrolled'] as bool? ?? false,
    );
  }

  int get spotsLeft => maxParticipants - enrolledCount;

  bool get isRecruiting => status == 'recruiting';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}
