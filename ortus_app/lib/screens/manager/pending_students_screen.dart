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
    final students = await _userService.getPendingStudents();
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
            onPressed: () => Navigator.pushNamed(context, '/create-student')
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
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) => _buildStudentCard(
                  _students[index],
                ),
              ),
      ),
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
        DateTime? parentDob;
        bool isCreatingParent = false;

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
                          'Карточка студента',
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
                      text: 'Назначить в группу',
                      onPressed: () {
                        Navigator.pop(context);
                        _assignStudent(student);
                      },
                    ),
                    const SizedBox(height: 28),
                    if (student.parent != null)
                      Card(
                        color: AppColors.primary.withValues(alpha: 0.05),
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
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'ФИО',
                                value: student.parent!.fullName,
                              ),
                              _InfoRow(
                                label: 'Телефон',
                                value: student.parent!.phoneNumber,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
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
                                            .split(' ')
                                            .first,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
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
          'Нет новых заявок',
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
