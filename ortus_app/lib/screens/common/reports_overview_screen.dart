import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class ReportsOverviewScreen extends StatefulWidget {
  final String title;

  const ReportsOverviewScreen({super.key, this.title = 'Отчёты тренеров'});

  @override
  State<ReportsOverviewScreen> createState() => _ReportsOverviewScreenState();
}

class _ReportsOverviewScreenState extends State<ReportsOverviewScreen> {
  DateTimeRange? _range;
  bool _lateOnly = false;
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    DateTime? from;
    DateTime? to;
    if (_range != null) {
      from = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
      to = DateTime(
        _range!.end.year,
        _range!.end.month,
        _range!.end.day,
        23,
        59,
        59,
        999,
      );
    }

    setState(() {
      _reportsFuture = ReportService().getReports(
        dateFrom: from,
        dateTo: to,
        isLate: _lateOnly ? true : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<ReportModel>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 72,
                          color: AppColors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text('Отчётов пока нет'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ReportCard(report: reports[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final rangeLabel = _range == null
        ? 'Все даты'
        : '${DateFormatter.formatDate(_range!.start)} — ${DateFormatter.formatDate(_range!.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(rangeLabel),
          ),
          FilterChip(
            label: const Text('Только опоздания'),
            selected: _lateOnly,
            onSelected: (value) {
              setState(() => _lateOnly = value);
              _load();
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
          if (_range != null || _lateOnly)
            TextButton(
              onPressed: () {
                setState(() {
                  _range = null;
                  _lateOnly = false;
                });
                _load();
              },
              child: const Text('Сбросить'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (range != null) {
      setState(() => _range = range);
      _load();
    }
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.trainerName.isEmpty
                        ? 'Тренер'
                        : report.trainerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _LateChip(isLate: report.isLate),
              ],
            ),
            const SizedBox(height: 6),
            if (report.trainerPhone.isNotEmpty)
              Text(
                'Телефон: ${report.trainerPhone}',
                style: TextStyle(color: AppColors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              'Дата: ${DateFormatter.formatDate(report.trainingDate)}',
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            Text('Слот: ${report.slot}'),
            if (report.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: ${report.comment}'),
            ],
            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.attachments
                    .map((attachment) => _AttachmentChip(attachment: attachment))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LateChip extends StatelessWidget {
  final bool isLate;
  const _LateChip({required this.isLate});

  @override
  Widget build(BuildContext context) {
    final color = isLate ? Colors.redAccent : Colors.green;
    final label = isLate ? 'Опоздал' : 'В срок';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final ReportAttachment attachment;

  const _AttachmentChip({required this.attachment});

  IconData _iconForType(String type) {
    if (type.startsWith('image/')) return Icons.image_outlined;
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.contains('word')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () async {
        final uri = Uri.tryParse(attachment.url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      label: Text(
        attachment.originalName.isEmpty ? 'Файл' : attachment.originalName,
        overflow: TextOverflow.ellipsis,
      ),
      avatar: Icon(_iconForType(attachment.fileType), size: 18),
    );
  }
}
