import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cleaning_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cleaning_report_service.dart';
import '../../utils/constants.dart';

class CleaningHistoryScreen extends StatefulWidget {
  const CleaningHistoryScreen({super.key});

  @override
  State<CleaningHistoryScreen> createState() => _CleaningHistoryScreenState();
}

class _CleaningHistoryScreenState extends State<CleaningHistoryScreen> {
  final _service = CleaningReportService();
  late Future<List<CleaningReportModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getReports();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getReports();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAllowed =
        user?.hasRole('tech_staff') == true ||
        user?.isAdmin == true ||
        user?.hasRole('director') == true ||
        user?.hasRole('manager') == true;

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('История уборок'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Нет доступа')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'История уборок',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: FutureBuilder<List<CleaningReportModel>>(
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
                  Icon(
                    Icons.cleaning_services,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Отчётов пока нет',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              );
            }

            final reports = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                report.staffName.isEmpty
                                    ? 'Сотрудник'
                                    : report.staffName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(report.date),
                              style: const TextStyle(color: AppColors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: report.zones
                              .map(
                                (zone) => Chip(
                                  label: Text(_zoneLabel(zone)),
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                ),
                              )
                              .toList(),
                        ),
                        if (report.comment != null &&
                            report.comment!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              report.comment!,
                              style: const TextStyle(color: AppColors.black),
                            ),
                          ),
                        if (report.photos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: report.photos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, photoIndex) {
                                final url = report.photos[photoIndex];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 110,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 110,
                                      height: 90,
                                      color: AppColors.grey.withOpacity(0.2),
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _zoneLabel(String zone) {
    switch (zone) {
      case 'hall':
        return 'Зал';
      case 'locker_room':
        return 'Раздевалка';
      case 'shower':
        return 'Душевая';
      case 'corridor':
        return 'Коридор';
      default:
        return zone;
    }
  }
}
