import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/date_picker_helper.dart';
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
  String _statusFilter = 'all';
  final _searchController = TextEditingController();

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
    final students = await _userService.getStudents(
      status: _statusFilter == 'all' ? null : _statusFilter,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          content: Text('Не удалось назначить ученика'),
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
          backgroundColor: AppColors.black,
          title: const Text(
            'Новые ученики',
            style: TextStyle(
              color: Colors.white, // белый цвет текста
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white, // если есть иконка "назад" и т.п.
          ),
          foregroundColor:
              Colors.white, // дефолтный цвет текста/иконок в AppBar
        ),
        body: const Center(child: Text('Доступно только менеджерам')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ученики клуба'),
        backgroundColor: AppColors.black,
        actions: [
          _buildWhiteActionButton(
            icon: Icons.person_add,
            onPressed: () => Navigator.pushNamed(context, '/create-student')
                .then((_) => _loadStudents()),
          ),
          _buildWhiteActionButton(
            icon: Icons.refresh,
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
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
                      _buildSearch(),
                      const SizedBox(height: 12),
                      _buildStatusFilters(),
                      const SizedBox(height: 16),
                      ..._students.map(_buildStudentCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWhiteActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Поиск по ФИО или телефону',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) => _loadStudents(),
    );
  }

  Widget _buildStatusFilters() {
    const statuses = {
      'all': 'Все',
      'pending': 'Ожидают',
      'active': 'Активные',
      'inactive': 'Неактивные',
    };

    return Wrap(
      spacing: 8,
      children: statuses.entries.map((entry) {
        final selected = _statusFilter == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) {
            setState(() => _statusFilter = entry.key);
            _loadStudents();
          },
        );
      }).toList(),
    );
  }

  Widget _buildStudentCard(UserData student) {
    final createdAt = student.createdAt;
    return InkWell(
      onTap: () => _openStudentDetails(student),
      child: Card(
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
                  const Icon(Icons.info_outline, color: AppColors.grey),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Телефон', value: student.phoneNumber),
              _InfoRow(label: 'ИИН', value: student.iin),
              if (createdAt != null)
                _InfoRow(
                  label: 'Создан',
                  value: DateFormatter.formatDateTime(createdAt),
                ),
              const SizedBox(height: 12),
              Text(
                'Нажмите, чтобы посмотреть детали и создать родителя',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStudentDetails(UserData student) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final parentPhoneController = TextEditingController();
        final parentIinController = TextEditingController();
        final parentNameController = TextEditingController();
        final parentPasswordController = TextEditingController();
        final parentSearchController =
            TextEditingController(text: student.parent?.fullName ?? '');
        DateTime? parentDob;
        bool isCreatingParent = false;
        bool isSearchingParent = false;
        bool isAttachingParent = false;
        bool showCreateParentForm = false;
        List<UserData> parentResults = [];

        Future<void> submitParent(StateSetter setModalState) async {
          if (!formKey.currentState!.validate() || parentDob == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Заполните все поля родителя'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          setModalState(() => isCreatingParent = true);
          try {
            final updated = await _userService.createParentForStudent(
              studentId: student.id,
              phoneNumber: parentPhoneController.text,
              iin: parentIinController.text,
              fullName: parentNameController.text,
              dateOfBirth: parentDob!,
              password: parentPasswordController.text,
            );
            if (!context.mounted) return;
            if (updated != null) {
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            setModalState(() => isCreatingParent = false);
          }
        }

        Future<void> searchParents(StateSetter setModalState) async {
          if (parentSearchController.text.trim().isEmpty) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('Введите ФИО для поиска'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          setModalState(() {
            isSearchingParent = true;
            parentResults = [];
          });
          try {
            final results = await _userService.searchParents(
              parentSearchController.text.trim(),
            );
            if (!context.mounted) return;
            setModalState(() {
              parentResults = results;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            setModalState(() => isSearchingParent = false);
          }
        }

        Future<void> attachParent(
          StateSetter setModalState,
          UserData parent,
        ) async {
          setModalState(() => isAttachingParent = true);
          try {
            final updated = await _userService.attachParentToStudent(
              studentId: student.id,
              parentId: parent.id,
            );
            if (!context.mounted) return;
            if (updated != null) {
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            setModalState(() => isAttachingParent = false);
          }
        }

        Widget parentSearchField(StateSetter setModalState) {
          return TextField(
            controller: parentSearchController,
            decoration: InputDecoration(
              labelText: 'Поиск родителя по ФИО',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: isSearchingParent
                        ? null
                        : () => searchParents(setModalState),
                  ),
                  IconButton(
                    icon: Icon(showCreateParentForm ? Icons.close : Icons.add),
                    onPressed: () {
                      setModalState(() {
                        showCreateParentForm = !showCreateParentForm;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Карточка ученика',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'ФИО', value: student.fullName),
                    _InfoRow(label: 'Телефон', value: student.phoneNumber),
                    _InfoRow(label: 'ИИН', value: student.iin),
                    if (student.groupName != null)
                      _InfoRow(label: 'Группа', value: student.groupName!),
                    if (student.status != null)
                      _InfoRow(label: 'Статус', value: student.status!),
                    if (student.createdAt != null)
                      _InfoRow(
                        label: 'Создан',
                        value: DateFormatter.formatDateTime(
                          student.createdAt!,
                        ),
                      ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: student.groupName == null
                          ? 'Назначить в группу'
                          : 'Сменить группу',
                      onPressed: () {
                        Navigator.pop(context);
                        _assignStudent(student);
                      },
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Родитель',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (student.parent != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'ФИО',
                                value: student.parent!.fullName,
                              ),
                              _InfoRow(
                                label: 'Телефон',
                                value: student.parent!.phoneNumber,
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                            ] else
                              const SizedBox(height: 8),
                            parentSearchField(setModalState),
                            if (isSearchingParent)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(),
                              ),
                            if (parentResults.isNotEmpty)
                              Column(
                                children: parentResults.map((parent) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(parent.fullName),
                                    subtitle: Text(parent.phoneNumber),
                                    trailing: isAttachingParent
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline,
                                            color: AppColors.primary,
                                          ),
                                    onTap: isAttachingParent
                                        ? null
                                        : () => attachParent(setModalState, parent),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (showCreateParentForm) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Создать родителя',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: parentNameController,
                              decoration: const InputDecoration(
                                labelText: 'ФИО родителя',
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Введите ФИО'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: parentPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Телефон родителя',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Введите телефон'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: parentIinController,
                              decoration:
                                  const InputDecoration(labelText: 'ИИН'),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value == null || value.length != 12
                                      ? 'ИИН 12 цифр'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: parentPasswordController,
                              decoration:
                                  const InputDecoration(labelText: 'Пароль'),
                              obscureText: true,
                              validator: (value) =>
                                  value == null || value.length < 6
                                      ? 'Минимум 6 символов'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    parentDob == null
                                        ? 'Дата рождения не выбрана'
                                        : parentDob!
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final picked = await showAppDatePicker(
                                      context: context,
                                      initialDate: DateTime(1990, 1, 1),
                                      firstDate: DateTime(1950),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() => parentDob = picked);
                                    }
                                  },
                                  child: const Text('Выбрать дату'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isCreatingParent
                                    ? null
                                    : () => submitParent(setModalState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                                child: isCreatingParent
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Text('Создать родителя'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadStudents();
    }
  }
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.emoji_people, size: 80, color: AppColors.grey),
        SizedBox(height: 16),
        Text(
          'Студенты ещё не добавлены',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.grey),
        ),
      ],
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
              color: AppColors.black.withValues(alpha: 0.7),
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
