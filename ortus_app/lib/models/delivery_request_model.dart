class DeliveryRequestModel {
  final String id;
  final String orderId;
  final String studentId;
  final String studentName;
  final String phoneNumber;
  final String summary;
  final String pickupAddress;
  final String desiredMethod;
  final String status;
  final DateTime createdAt;

  DeliveryRequestModel({
    required this.id,
    required this.orderId,
    required this.studentId,
    required this.studentName,
    required this.phoneNumber,
    required this.summary,
    required this.pickupAddress,
    required this.desiredMethod,
    required this.status,
    required this.createdAt,
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestModel(
      id: json['_id']?.toString() ?? '',
      orderId: json['orderId'] is Map
          ? json['orderId']['_id']?.toString() ?? ''
          : json['orderId']?.toString() ?? '',
      studentId: json['studentId'] is Map
          ? json['studentId']['_id']?.toString() ?? ''
          : json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ??
          (json['studentId'] is Map ? json['studentId']['fullName'] : '') ??
          '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      desiredMethod: json['desiredMethod']?.toString() ?? 'delivery',
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
