import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../utils/constants.dart';

class ScheduleListScreen extends StatelessWidget {
  const ScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Расписание',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: const _ScheduleBody(),
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  const _ScheduleBody();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScheduleModel>>(
      future: ScheduleService().getAllSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 80, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  'Расписание отсутствует',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final grouped = <int, List<ScheduleModel>>{};
        for (final schedule in snapshot.data!) {
          grouped.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
        }

        final days = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final entries = grouped[day]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entries.first.dayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...entries.map(_ScheduleCard.new),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;

  const _ScheduleCard(this.schedule);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.groupName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Text('${schedule.startTime} - ${schedule.endTime}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(schedule.location)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
