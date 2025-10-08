import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../utils/constants.dart';

class GroupDetailScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailScreen({required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(group.name, style: TextStyle(color: AppColors.white)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.white,
                  child: Icon(Icons.group, size: 50, color: AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  group.name,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Тренер: ${group.trainerName}',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ScheduleModel>>(
              future: ScheduleService().getScheduleByGroup(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: AppColors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нет расписания',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final schedules = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            schedule.dayShort,
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          schedule.dayName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${schedule.startTime} - ${schedule.endTime}\n${schedule.location}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
