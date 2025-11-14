import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_model.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class TrainerGroupsScreen extends StatefulWidget {
  const TrainerGroupsScreen({super.key});

  @override
  State<TrainerGroupsScreen> createState() => _TrainerGroupsScreenState();
}

class _TrainerGroupsScreenState extends State<TrainerGroupsScreen> {
  final _groupService = GroupService();
  final _userService = UserService();

  List<GroupModel> _groups = [];
  bool _isLoading = true;
  final Map<String, List<UserData>> _studentsByGroup = {};
  final Map<String, bool> _studentsLoading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final allGroups = await _groupService.getAllGroups();
    final myGroups = allGroups
        .where((group) => group.trainerId == user?.id)
        .toList();
    if (!mounted) return;
    setState(() {
      _groups = myGroups;
      _isLoading = false;
    });
  }

  Future<void> _loadStudents(String groupId) async {
    if (_studentsByGroup.containsKey(groupId)) return;
    setState(() => _studentsLoading[groupId] = true);
    final students = await _userService.getStudents(groupId: groupId);
    if (!mounted) return;
    setState(() {
      _studentsByGroup[groupId] = students;
      _studentsLoading[groupId] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Мои группы',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _groups.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGroups,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final students = _studentsByGroup[group.id];
                      final isLoadingStudents =
                          _studentsLoading[group.id] ?? false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Ученики: ${students?.length ?? group.studentCount}',
                            style: const TextStyle(color: AppColors.grey),
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade700,
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              _loadStudents(group.id);
                            }
                          },
                          children: [
                            if (isLoadingStudents)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            else if (students == null || students.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'У этой группы пока нет студентов.',
                                  style: TextStyle(color: AppColors.grey),
                                ),
                              )
                            else
                              ...students.map(
                                (student) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      student.fullName.isNotEmpty
                                          ? student.fullName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(student.fullName),
                                  subtitle: Text(
                                    'Телефон: ${student.phoneNumber}\nИИН: ${student.iin}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.groups, size: 80, color: AppColors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'У вас пока нет назначенных групп.',
            style: TextStyle(color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
