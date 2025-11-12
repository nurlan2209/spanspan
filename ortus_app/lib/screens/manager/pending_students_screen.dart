import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_button.dart';

class PendingStudentsScreen extends StatefulWidget {
  const PendingStudentsScreen({super.key});

  @override
  State<PendingStudentsScreen> createState() => _PendingStudentsScreenState();
}

class _PendingStudentsScreenState extends State<PendingStudentsScreen> {
  final _userService = UserService();
  final _groupService = GroupService();

  List<UserData> _students = [];
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  bool _isGroupsLoading = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadStudents(), _loadGroups()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStudents() async {
    String? period;
    if (_filter == 'day') period = 'day';
    if (_filter == 'week') period = 'week';

    final students = await _userService.getPendingStudents(period: period);
    if (mounted) {
      setState(() {
        _students = students;
      });
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _isGroupsLoading = true);
    final groups = await _groupService.getAllGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isGroupsLoading = false;
      });
    }
  }

  void _changeFilter(String newFilter) {
    if (_filter == newFilter) return;
    setState(() => _filter = newFilter);
    _loadStudents();
  }

  Future<void> _assignStudent(UserData student) async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нет доступных групп. Создайте группу в разделе тренеров.',
          ),
        ),
      );
      return;
    }

    final groupId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Выберите группу',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (_isGroupsLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return ListTile(
                        title: Text(group.name),
                        subtitle: Text('Тренер: ${group.trainerName}'),
                        onTap: () => Navigator.pop(context, group.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (groupId == null) return;

    final assigned = await _userService.assignStudentToGroup(
      studentId: student.id,
      groupId: groupId,
    );

    if (assigned != null) {
      if (mounted) {
        setState(() {
          _students.removeWhere((element) => element.id == student.id);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${student.fullName} назначен в группу ${assigned.groupName ?? ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось назначить студента'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null || !user.hasRole('manager')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Новые студенты'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Доступно только менеджерам')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новые студенты'),
        backgroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () =>
                Navigator.pushNamed(context, '/create-student')
                    .then((_) => _loadStudents()),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _students.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  ..._students.map(_buildStudentCard),
                ],
              ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _FilterChip(
          label: 'Все',
          isSelected: _filter == 'all',
          onTap: () => _changeFilter('all'),
        ),
        _FilterChip(
          label: 'Сегодня',
          isSelected: _filter == 'day',
          onTap: () => _changeFilter('day'),
        ),
        _FilterChip(
          label: 'Неделя',
          isSelected: _filter == 'week',
          onTap: () => _changeFilter('week'),
        ),
      ],
    );
  }

  Widget _buildStudentCard(UserData student) {
    final createdAt = student.createdAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Телефон', value: student.phoneNumber),
            _InfoRow(label: 'ИИН', value: student.iin),
            if (createdAt != null)
              _InfoRow(
                label: 'Заявка',
                value: DateFormatter.formatDateTime(createdAt),
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Назначить в группу',
              onPressed: () => _assignStudent(student),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.emoji_people, size: 80, color: AppColors.grey),
        SizedBox(height: 16),
        Text(
          'Нет новых заявок',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.grey),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.black,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.black.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.black)),
          ),
        ],
      ),
    );
  }
}
