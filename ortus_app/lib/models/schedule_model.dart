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
    final groupField = json['groupId'];
    String resolvedGroupId = '';
    String resolvedGroupName = '';

    if (groupField is Map<String, dynamic>) {
      resolvedGroupId = groupField['_id']?.toString() ?? '';
      resolvedGroupName = groupField['name']?.toString() ?? '';
    } else if (groupField != null) {
      resolvedGroupId = groupField.toString();
      resolvedGroupName = json['groupName']?.toString() ?? '';
    }

    return ScheduleModel(
      id: json['_id']?.toString() ?? '',
      groupId: resolvedGroupId,
      groupName: resolvedGroupName,
      dayOfWeek: json['dayOfWeek'] ?? 0,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
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
