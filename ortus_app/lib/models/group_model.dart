class GroupModel {
  final String id;
  final String name;
  final String trainerName;
  final String? trainerPhone;
  final String? trainerId;
  final int studentCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.trainerName,
    this.trainerPhone,
    this.trainerId,
    this.studentCount = 0,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final trainerData = json['trainerId'];
    String trainerName = 'Без тренера';
    String? trainerPhone;
    String? trainerId;
    int studentCount = 0;

    if (trainerData is Map<String, dynamic>) {
      trainerName = trainerData['fullName']?.toString() ?? trainerName;
      trainerPhone = trainerData['phoneNumber']?.toString();
      trainerId = trainerData['_id']?.toString();
    } else if (trainerData is String) {
      trainerId = trainerData;
    }
    final studentsData = json['students'];
    if (json['studentsCount'] is num) {
      studentCount = (json['studentsCount'] as num).toInt();
    } else if (studentsData is List) {
      studentCount = studentsData.length;
    }

    return GroupModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      trainerName: trainerName,
      trainerPhone: trainerPhone,
      trainerId: trainerId,
      studentCount: studentCount,
    );
  }
}
