import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class DirectorStudentsScreen extends StatefulWidget {
  const DirectorStudentsScreen({super.key});

  @override
  State<DirectorStudentsScreen> createState() => _DirectorStudentsScreenState();
}

class _DirectorStudentsScreenState extends State<DirectorStudentsScreen> {
  final _userService = UserService();
  final _groupService = GroupService();
  final _searchController = TextEditingController();

  List<UserData> _students = [];
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _statusFilter = 'all';
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadGroups(), _loadStudents()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.getAllGroups();
    if (mounted) {
      setState(() => _groups = groups);
    }
  }

  Future<void> _loadStudents() async {
    final students = await _userService.getStudents(
      search: _searchController.text.trim(),
      status: _statusFilter,
      groupId: _selectedGroupId,
    );
    if (mounted) {
      setState(() => _students = students);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadStudents();
    });
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canView = user?.hasRole('director') == true || user?.isAdmin == true;

    if (!canView) {
      return const Scaffold(
        body: Center(child: Text('Доступно только директору')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Студенты клуба',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportStudents,
            tooltip: 'Экспорт CSV',
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  if (_students.isEmpty)
                    const _EmptyState()
                  else
                    ..._students.map(_StudentCard.new),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Поиск по имени или телефону',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _loadStudents();
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: 'Все',
                isSelected: _statusFilter == 'all',
                onTap: () {
                  setState(() => _statusFilter = 'all');
                  _loadStudents();
                },
              ),
              _StatusChip(
                label: 'Активные',
                isSelected: _statusFilter == 'active',
                onTap: () {
                  setState(() => _statusFilter = 'active');
                  _loadStudents();
                },
              ),
              _StatusChip(
                label: 'Pending',
                isSelected: _statusFilter == 'pending',
                onTap: () {
                  setState(() => _statusFilter = 'pending');
                  _loadStudents();
                },
              ),
              _StatusChip(
                label: 'Неактивные',
                isSelected: _statusFilter == 'inactive',
                onTap: () {
                  setState(() => _statusFilter = 'inactive');
                  _loadStudents();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _selectedGroupId,
          decoration: InputDecoration(
            labelText: 'Группа',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Все группы'),
            ),
            ..._groups.map(
              (group) => DropdownMenuItem<String?>(
                value: group.id,
                child: Text(group.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedGroupId = value);
            _loadStudents();
          },
        ),
      ],
    );
  }

  Future<void> _exportStudents() async {
    setState(() => _isExporting = true);
    final success = await _userService.exportStudents(
      status: _statusFilter,
      groupId: _selectedGroupId,
      search: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isExporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'CSV-файл будет доступен в административной панели.'
              : 'Не удалось экспортировать студентов',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserData student;

  const _StudentCard(this.student);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: student.status ?? 'active'),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone,
              label: 'Телефон',
              value: student.phoneNumber,
            ),
            _InfoRow(
              icon: Icons.school,
              label: 'Группа',
              value: student.groupName ?? 'Без группы',
            ),
            if (student.parent != null)
              _InfoRow(
                icon: Icons.family_restroom,
                label: 'Родитель',
                value: student.parent!.fullName,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'В ожидании';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Неактивен';
        break;
      default:
        color = Colors.green;
        label = 'Активен';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.black)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.info_outline, size: 64, color: AppColors.grey),
        const SizedBox(height: 12),
        const Text(
          'Студенты не найдены',
          style: TextStyle(color: AppColors.grey),
        ),
      ],
    );
  }
}
