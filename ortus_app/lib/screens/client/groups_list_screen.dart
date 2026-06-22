import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';
import 'group_detail_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Группы'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.groups.isEmpty) {
            return const Center(
              child: Text('Нет доступных групп для вашего возраста',
                  style: TextStyle(color: AppColors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadGroups(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final group = provider.groups[i];
                return _GroupCard(
                  group: group,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                    );
                    if (mounted) provider.loadGroups();
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

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = group.spotsLeft;
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
                  if (group.isEnrolled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text('Записан', style: TextStyle(fontSize: 11, color: Colors.green)),
                    ),
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
                    DateFormat('dd.MM.yyyy, HH:mm').format(group.scheduledAt.toLocal()),
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.cake, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text('${group.ageMin}–${group.ageMax} лет',
                      style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 14,
                    color: spotsLeft <= 3 ? Colors.orange : AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    spotsLeft > 0 ? 'Осталось $spotsLeft мест' : 'Мест нет',
                    style: TextStyle(
                      color: spotsLeft <= 3 ? Colors.orange : AppColors.grey,
                      fontSize: 13,
                      fontWeight: spotsLeft <= 3 ? FontWeight.w600 : FontWeight.normal,
                    ),
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
