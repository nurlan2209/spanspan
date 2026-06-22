import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';
import 'group_detail_screen.dart';

class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({super.key});

  @override
  State<MyEnrollmentsScreen> createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadMyEnrollments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Мои записи'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.myEnrollments.isEmpty) {
            return const Center(
              child: Text('Вы ещё не записались ни в одну группу',
                  style: TextStyle(color: AppColors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadMyEnrollments(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myEnrollments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final group = provider.myEnrollments[i];
                return _EnrollmentCard(
                  group: group,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                    );
                    if (mounted) provider.loadMyEnrollments();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  const _EnrollmentCard({required this.group, required this.onTap});

  Color get _statusColor {
    switch (group.status) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'completed': return AppColors.grey;
      default: return Colors.orange;
    }
  }

  String get _statusLabel {
    switch (group.status) {
      case 'confirmed': return 'Подтверждено';
      case 'cancelled': return 'Отменено';
      case 'completed': return 'Завершено';
      default: return 'Ожидает подтверждения';
    }
  }

  IconData get _statusIcon {
    switch (group.status) {
      case 'confirmed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'completed': return Icons.done_all;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(group.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Icon(_statusIcon, size: 16, color: _statusColor),
                  const SizedBox(width: 4),
                  Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(group.trainerName ?? 'Тренер',
                      style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    group.scheduleLabel,
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
