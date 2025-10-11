class PaymentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String groupId;
  final String groupName;
  final double amount;
  final int month;
  final int year;
  final String status;
  final String paymentMethod;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.groupId,
    required this.groupName,
    required this.amount,
    required this.month,
    required this.year,
    required this.status,
    required this.paymentMethod,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'],
      studentId: json['studentId'] is String
          ? json['studentId']
          : json['studentId']['_id'],
      studentName: json['studentId'] is String
          ? ''
          : json['studentId']['fullName'],
      groupId: json['groupId'] is String
          ? json['groupId']
          : json['groupId']['_id'],
      groupName: json['groupId'] is String ? '' : json['groupId']['name'],
      amount: json['amount'].toDouble(),
      month: json['month'],
      year: json['year'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get monthName {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }

  String get periodText => '$monthName $year';

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
}
