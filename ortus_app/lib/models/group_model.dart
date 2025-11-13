class GroupModel {
  final String id;
  final String name;
  final String trainerName;
  final String? trainerPhone;

  GroupModel({
    required this.id,
    required this.name,
    required this.trainerName,
    this.trainerPhone,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final trainerData = json['trainerId'];
    String trainerName = 'Без тренера';
    String? trainerPhone;

    if (trainerData is Map<String, dynamic>) {
      trainerName = trainerData['fullName']?.toString() ?? trainerName;
      trainerPhone = trainerData['phoneNumber']?.toString();
    }

    return GroupModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      trainerName: trainerName,
      trainerPhone: trainerPhone,
    );
  }
}
