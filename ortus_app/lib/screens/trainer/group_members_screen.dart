import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../utils/constants.dart';

class GroupMembersScreen extends StatefulWidget {
  final GroupModel group;
  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await context.read<GroupProvider>().getMembers(widget.group.id);
      if (mounted) setState(() { _members = members; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _calcAge(String? birthDate) {
    if (birthDate == null) return 0;
    final dob = DateTime.tryParse(birthDate);
    if (dob == null) return 0;
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _members.isEmpty
              ? const Center(
                  child: Text('Пока никто не записался', style: TextStyle(color: AppColors.grey)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: AppColors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${_members.length} из ${widget.group.maxParticipants} участников',
                            style: const TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.cake, size: 16, color: AppColors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.group.ageMin}–${widget.group.ageMax} лет',
                            style: const TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final m = _members[i];
                          final age = _calcAge(m['birthDate']?.toString());
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  (m['fullName']?.toString() ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(m['fullName']?.toString() ?? ''),
                              subtitle: Text(
                                m['birthDate'] != null ? '$age лет' : 'Возраст не указан',
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                              trailing: Text(
                                DateFormat('dd.MM').format(
                                  DateTime.tryParse(m['enrolledAt']?.toString() ?? '') ?? DateTime.now(),
                                ),
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
