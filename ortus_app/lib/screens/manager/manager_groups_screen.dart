import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../utils/constants.dart';

class ManagerGroupsScreen extends StatefulWidget {
  const ManagerGroupsScreen({super.key});

  @override
  State<ManagerGroupsScreen> createState() => _ManagerGroupsScreenState();
}

class _ManagerGroupsScreenState extends State<ManagerGroupsScreen> {
  final _service = GroupService();
  late Future<List<GroupModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllGroups();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getAllGroups();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Группы клуба',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: FutureBuilder<List<GroupModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.groups, size: 72, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Группы ещё не созданы',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              );
            }

            final groups = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.groups, color: AppColors.primary),
                    ),
                    title: Text(group.name),
                    subtitle: Text('Тренер: ${group.trainerName}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
