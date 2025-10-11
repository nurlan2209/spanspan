class AttendanceModel {
  final String id;
  final String scheduleId;
  final String groupId;
  final String groupName;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.scheduleId,
    required this.groupId,
    required this.groupName,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id'],
      scheduleId: json['scheduleId'] is String
          ? json['scheduleId']
          : json['scheduleId']['_id'],
      groupId: json['groupId'] is String
          ? json['groupId']
          : json['groupId']['_id'],
      groupName: json['groupId'] is String ? '' : json['groupId']['name'],
      studentId: json['studentId'] is String
          ? json['studentId']
          : json['studentId']['_id'],
      studentName: json['studentId'] is String
          ? ''
          : json['studentId']['fullName'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      note: json['note'],
    );
  }

  String get statusText {
    switch (status) {
      case 'present':
        return 'Присутствовал';
      case 'absent':
        return 'Отсутствовал';
      case 'sick':
        return 'Болезнь';
      case 'competition':
        return 'Соревнования';
      case 'excused':
        return 'Уважительная';
      default:
        return status;
    }
  }

  bool get isPresent => status == 'present';
}

class AttendanceStats {
  final int total;
  final int present;
  final int absent;
  final int sick;
  final int competition;
  final int excused;
  final double attendanceRate;

  AttendanceStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.sick,
    required this.competition,
    required this.excused,
    required this.attendanceRate,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      total: json['total'],
      present: json['present'],
      absent: json['absent'],
      sick: json['sick'] ?? 0,
      competition: json['competition'] ?? 0,
      excused: json['excused'] ?? 0,
      attendanceRate: double.parse(json['attendanceRate'].toString()),
    );
  }
}
