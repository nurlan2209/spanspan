class UserModel {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final double weight;
  final String userType;
  final String? groupId;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.iin,
    required this.fullName,
    required this.dateOfBirth,
    required this.weight,
    required this.userType,
    this.groupId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      phoneNumber: json['phoneNumber'],
      iin: json['iin'],
      fullName: json['fullName'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      weight: json['weight'].toDouble(),
      userType: json['userType'],
      groupId: json['groupId']?['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'iin': iin,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'weight': weight,
      'userType': userType,
      'groupId': groupId,
    };
  }
}
