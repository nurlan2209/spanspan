class ScheduleModel {
  final String id;
  final String groupId;
  final String groupName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String location;

  ScheduleModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['_id'],
      groupId: json['groupId']['_id'] ?? json['groupId'],
      groupName: json['groupId']['name'] ?? '',
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
    );
  }

  String get dayName {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return days[dayOfWeek];
  }

  String get dayShort {
    const days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return days[dayOfWeek];
  }
}
