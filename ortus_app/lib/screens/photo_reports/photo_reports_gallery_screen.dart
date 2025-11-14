import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/photo_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/photo_report_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_picker_helper.dart';

class PhotoReportsGalleryScreen extends StatefulWidget {
  const PhotoReportsGalleryScreen({super.key});

  @override
  State<PhotoReportsGalleryScreen> createState() =>
      _PhotoReportsGalleryScreenState();
}

class _PhotoReportsGalleryScreenState extends State<PhotoReportsGalleryScreen> {
  final _service = PhotoReportService();
  List<PhotoReportModel> _reports = [];
  bool _isLoading = true;
  String _filterType = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final data = await _service.getPhotoReports(
      type: _filterType == 'all' ? null : _filterType,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    if (!mounted) return;
    setState(() {
      _reports = data;
      _isLoading = false;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showAppDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _loadReports();
    }
  }

  void _clearDates() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAllowed =
        user?.hasRole('director') == true ||
        user?.isAdmin == true ||
        user?.hasRole('manager') == true;

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Фотоотчёты'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Нет доступа')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Фотоотчёты',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        color: AppColors.primary,
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _reports.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [
                        SizedBox(height: 60),
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Фотоотчётов пока нет',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) =>
                          _ReportCard(report: _reports[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const chips = [
      ('all', 'Все'),
      ('training_before', 'До тренировки'),
      ('training_after', 'После тренировки'),
      ('cleaning', 'Уборка'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: chips
                .map(
                  (chip) => ChoiceChip(
                    label: Text(chip.$2),
                    selected: _filterType == chip.$1,
                    onSelected: (_) {
                      setState(() => _filterType = chip.$1);
                      _loadReports();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateFrom == null
                        ? 'Дата с'
                        : _dateFrom!.toString().split(' ').first,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    _dateTo == null
                        ? 'Дата по'
                        : _dateTo!.toString().split(' ').first,
                  ),
                ),
              ),
            ],
          ),
          if (_dateFrom != null || _dateTo != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearDates,
                child: const Text('Сбросить даты'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final PhotoReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
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
                Chip(
                  label: Text(_typeLabel(report.type)),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.authorName.isEmpty ? 'Сотрудник' : report.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatDate(report.createdAt),
                  style: const TextStyle(color: AppColors.grey),
                ),
              ],
            ),
            if (report.comment != null && report.comment!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(report.comment!),
              ),
            if (report.photos.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, photoIndex) {
                    final url = report.photos[photoIndex];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 140,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 120,
                          color: AppColors.grey.withOpacity(0.2),
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'training_before':
        return 'До тренировки';
      case 'training_after':
        return 'После тренировки';
      case 'cleaning':
        return 'Уборка';
      default:
        return type;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$day.$month ${date.year} $time';
  }
}
