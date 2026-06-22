import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';
import 'create_group_screen.dart';
import 'group_members_screen.dart';

class TrainerGroupsScreen extends StatefulWidget {
  const TrainerGroupsScreen({super.key});

  @override
  State<TrainerGroupsScreen> createState() => _TrainerGroupsScreenState();
}

class _TrainerGroupsScreenState extends State<TrainerGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadTrainerGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Мои группы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
              if (mounted) context.read<GroupProvider>().loadTrainerGroups();
            },
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.trainerGroups.isEmpty) {
            return const Center(
              child: Text('Нет групп. Создайте первую!', style: TextStyle(color: AppColors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadTrainerGroups(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.trainerGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _GroupCard(group: provider.trainerGroups[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  const _GroupCard({required this.group});

  Color get _statusColor {
    switch (group.status) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'completed': return AppColors.grey;
      default: return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (group.status) {
      case 'confirmed': return 'Подтверждена';
      case 'cancelled': return 'Отменена';
      case 'completed': return 'Завершена';
      default: return 'Набор идёт';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupProvider>();
    return Card(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy, HH:mm').format(group.scheduledAt.toLocal()),
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text('${group.enrolledCount}/${group.maxParticipants} участников',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.cake, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text('${group.ageMin}–${group.ageMax} лет',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13)),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(group.description, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.people_alt, size: 16),
                  label: const Text('Участники'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GroupMembersScreen(group: group)),
                  ),
                ),
                const SizedBox(width: 8),
                if (group.isRecruiting) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final err = await provider.confirmGroup(group.id);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('Подтвердить', style: TextStyle(color: AppColors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Отменить группу?'),
                          content: const Text('Все записи будут аннулированы.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Да', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final err = await provider.cancelGroup(group.id);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
