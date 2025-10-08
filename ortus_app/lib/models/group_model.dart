class GroupModel {
  final String id;
  final String name;
  final String trainerName;

  GroupModel({required this.id, required this.name, required this.trainerName});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'],
      name: json['name'],
      trainerName: json['trainerId']['fullName'],
    );
  }
}
