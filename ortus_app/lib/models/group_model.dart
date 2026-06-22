class GroupModel {
  final String id;
  final String title;
  final String description;
  final String trainerId;
  final String? trainerName;
  final List<int> scheduleDays;
  final String scheduleTime;
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
    required this.scheduleDays,
    required this.scheduleTime,
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
      scheduleDays: (json['scheduleDays'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      scheduleTime: json['scheduleTime']?.toString() ?? '',
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

  // 1=Пн ... 7=Вс
  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String get scheduleLabel {
    final days = (scheduleDays.toList()..sort())
        .map((d) => _dayNames[(d - 1).clamp(0, 6)])
        .join(', ');
    return '$days • $scheduleTime';
  }
}
