class UserModel {
  final String id;
  final String phoneNumber;
  final String iin;
  final String fullName;
  final DateTime dateOfBirth;
  final double weight;
  final List<String> userType;
  final String? groupId;
  final List<UserModel>? children;
  final UserModel? parent;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.iin,
    required this.fullName,
    required this.dateOfBirth,
    required this.weight,
    required this.userType,
    this.groupId,
    this.children,
    this.parent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      phoneNumber: json['phoneNumber'],
      iin: json['iin'],
      fullName: json['fullName'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      weight: json['weight'].toDouble(),
      userType: List<String>.from(json['userType']),
      groupId: json['groupId']?['_id'],
      children: json['children'] != null
          ? (json['children'] as List)
                .map((child) => UserModel.fromJson(child))
                .toList()
          : null,
      parent: json['parentId'] != null
          ? UserModel.fromJson(json['parentId'])
          : null,
    );
  }

  bool hasRole(String role) => userType.contains(role);
  bool get isStudent => hasRole('student');
  bool get isTrainer => hasRole('trainer');
  bool get isParent => hasRole('parent');
  bool get isAdmin => hasRole('admin');
}
