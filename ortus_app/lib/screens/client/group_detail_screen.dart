import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';

class GroupDetailScreen extends StatelessWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(Icons.person, 'Тренер', group.trainerName ?? 'Не указан'),
                    const Divider(),
                    _InfoRow(Icons.calendar_today, 'Расписание', group.scheduleLabel),
                    const Divider(),
                    _InfoRow(Icons.cake, 'Возраст', '${group.ageMin}–${group.ageMax} лет'),
                    const Divider(),
                    _InfoRow(
                      Icons.people,
                      'Места',
                      '${group.enrolledCount}/${group.maxParticipants} (осталось ${group.spotsLeft})',
                    ),
                  ],
                ),
              ),
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Описание',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(group.description),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _EnrollButton(group: group),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EnrollButton extends StatefulWidget {
  final GroupModel group;
  const _EnrollButton({required this.group});

  @override
  State<_EnrollButton> createState() => _EnrollButtonState();
}

class _EnrollButtonState extends State<_EnrollButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    if (!g.isRecruiting) {
      return Center(
        child: Text(
          g.isConfirmed ? 'Набор завершён' : 'Группа недоступна',
          style: const TextStyle(color: AppColors.grey),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : g.isEnrolled
              ? OutlinedButton(
                  onPressed: _unenroll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Отписаться'),
                )
              : ElevatedButton(
                  onPressed: g.spotsLeft > 0 ? _enroll : null,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(
                    g.spotsLeft > 0 ? 'Записаться' : 'Мест нет',
                    style: const TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                ),
    );
  }

  Future<void> _enroll() async {
    setState(() => _loading = true);
    final err = await context.read<GroupProvider>().enroll(widget.group.id);
    setState(() => _loading = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы записаны!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _unenroll() async {
    setState(() => _loading = true);
    final err = await context.read<GroupProvider>().unenroll(widget.group.id);
    setState(() => _loading = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }
  }
}
