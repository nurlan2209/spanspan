import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../create_user_screen.dart';

class DirectorStaffScreen extends StatelessWidget {
  const DirectorStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.black,
          title: const Text(
            'Сотрудники',
            style: TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Список'),
              Tab(text: 'Создать аккаунт'),
            ],
          ),
        ),
        body: const TabBarView(children: [_StaffListTab(), CreateUserScreen()]),
      ),
    );
  }
}

class _StaffListTab extends StatefulWidget {
  const _StaffListTab();

  @override
  State<_StaffListTab> createState() => _StaffListTabState();
}

class _StaffListTabState extends State<_StaffListTab> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<UserData> _staff = [];
  bool _isLoading = true;
  String _roleFilter = 'all';
  String? _updatingStaffId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final data = await _userService.getStaff(
      role: _roleFilter,
      search: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _staff = data;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadStaff);
  }

  Future<void> _toggleStatus(UserData staff) async {
    final newStatus = staff.status == 'inactive' ? 'active' : 'inactive';
    setState(() => _updatingStaffId = staff.id);

    final updated = await _userService.updateUserStatus(
      userId: staff.id,
      status: newStatus,
    );

    if (!mounted) return;

    setState(() {
      _updatingStaffId = null;
      if (updated != null) {
        final index = _staff.indexWhere((s) => s.id == staff.id);
        if (index != -1) {
          _staff[index] = updated;
        }
      }
    });
  }

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
      return const Center(child: Text('Доступно только директору'));
    }

    return RefreshIndicator(
      onRefresh: _loadStaff,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildRoleFilters(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_staff.isEmpty)
            const _StaffEmptyState()
          else
            ..._staff.map(
              (user) => _StaffCard(
                staff: user,
                isUpdating: _updatingStaffId == user.id,
                onToggleStatus: () => _toggleStatus(user),
              ),
            ),
        ],
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
                  _loadStaff();
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRoleFilters() {
    final roles = {
      'all': 'Все',
      'trainer': 'Тренеры',
      'manager': 'Менеджеры',
      'tech_staff': 'Технички',
      'admin': 'Админы',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.entries.map((entry) {
          final isSelected = _roleFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _roleFilter = entry.key);
                _loadStaff();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UserData staff;
  final bool isUpdating;
  final VoidCallback onToggleStatus;

  const _StaffCard({
    required this.staff,
    required this.isUpdating,
    required this.onToggleStatus,
  });

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
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    staff.fullName.isNotEmpty
                        ? staff.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        staff.userType.join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (staff.groupName != null)
                  Chip(
                    label: Text(staff.groupName!),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                const SizedBox(width: 8),
                _StatusPill(status: staff.status ?? 'active'),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone,
              label: 'Телефон',
              value: staff.phoneNumber,
            ),
            _InfoRow(icon: Icons.badge, label: 'ИИН', value: staff.iin),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isUpdating ? null : onToggleStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: staff.status == 'inactive'
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: AppColors.white,
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        staff.status == 'inactive'
                            ? 'Активировать'
                            : 'Деактивировать',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'inactive':
        color = Colors.grey;
        label = 'Неактивен';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.green;
        label = 'Активен';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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

class _StaffEmptyState extends StatelessWidget {
  const _StaffEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.info_outline, size: 64, color: AppColors.grey),
        const SizedBox(height: 12),
        const Text(
          'Сотрудники не найдены',
          style: TextStyle(color: AppColors.grey),
        ),
      ],
    );
  }
}
