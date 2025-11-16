import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/photo_report_model.dart';
import '../../models/schedule_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';
import '../../services/photo_report_service.dart';
import '../../services/schedule_service.dart';
import '../../services/training_session_service.dart';
import '../../utils/constants.dart';

class PhotoReportScreen extends StatefulWidget {
  final String? initialType;
  final String? initialScheduleId;

  const PhotoReportScreen({
    super.key,
    this.initialType,
    this.initialScheduleId,
  });

  @override
  State<PhotoReportScreen> createState() => _PhotoReportScreenState();
}

class _PhotoReportScreenState extends State<PhotoReportScreen> {
  final _commentController = TextEditingController();
  final _cleaningReportController = TextEditingController();
  final _picker = ImagePicker();
  final _service = PhotoReportService();
  final _groupService = GroupService();
  final _scheduleService = ScheduleService();
  final _sessionService = TrainingSessionService();

  String _selectedType = 'training_before';
  String? _selectedTrainingId;
  String? _pendingInitialScheduleId;
  bool _isSubmitting = false;
  bool _isLoadingTrainings = false;
  bool _isLoadingLatestReports = false;
  String? _latestReportsScheduleId;
  bool _trainingsInitialized = false;
  final DateTime _today = _now;
  List<ScheduleModel> _todayTrainings = [];
  Map<String, TrainingSessionStatus> _sessionStatuses = {};
  PhotoReportModel? _latestBeforeReport;
  PhotoReportModel? _latestAfterReport;
  List<XFile> _images = [];
  bool _argsApplied = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? _selectedType;
    _pendingInitialScheduleId = widget.initialScheduleId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshTrainingOptions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final type = args['type']?.toString();
      final scheduleId = args['scheduleId']?.toString();
      if (type != null && type.isNotEmpty) {
        _selectedType = type;
      }
      if (scheduleId != null && scheduleId.isNotEmpty) {
        _pendingInitialScheduleId = scheduleId;
      }
    }
    _argsApplied = true;
  }

  Future<void> _pickImages() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (result.isEmpty) return;
      setState(() {
        _images = result.take(10).toList();
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка выбора фото: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одно фото'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!kIsWeb && _images.any((image) => image.path.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный путь к файлу'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final relatedId = _resolveRelatedId();

    if (_selectedType.startsWith('training') &&
        (relatedId == null || relatedId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите тренировку из списка, чтобы продолжить'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedType == 'cleaning' &&
        (relatedId == null || relatedId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите ID отчёта по уборке'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final files = _images
          .map((xfile) => File(xfile.path))
          .where((file) => file.path.isNotEmpty)
          .toList();

      final effectiveType = _effectiveType;
      final lastTrainingId =
          _selectedType.startsWith('training') ? _selectedTrainingId : null;

      final success = await _service.createPhotoReport(
        type: effectiveType,
        relatedId: relatedId,
        comment: _commentController.text.trim(),
        photos: files,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _images = [];
          _commentController.clear();
          _cleaningReportController.clear();
          if (lastTrainingId != null) {
            _selectedTrainingId = lastTrainingId;
          }
        });
        if (_selectedType.startsWith('training') && lastTrainingId != null) {
          await _loadLatestReportsFor(lastTrainingId);
          await _refreshTrainingOptions();
        }
        if (!mounted) return;
        final thankYouMessage = effectiveType == 'training_after'
            ? 'Спасибо, тренировка завершена! Фото ПОСЛЕ принято.'
            : effectiveType == 'training_before'
                ? 'Спасибо! Фото ДО тренировки загружено.'
                : 'Отчёт отправлен.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(thankYouMessage),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось отправить отчёт'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isTrainer = user?.isTrainer ?? false;
    final isTechStaff = user?.hasRole('tech_staff') ?? false;

    final canWorkWithTraining =
        isTrainer || user?.isAdmin == true || user?.hasRole('director') == true;

    if (!canWorkWithTraining && !isTechStaff) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Фотоотчёт'),
          backgroundColor: AppColors.black,
        ),
        body: const Center(child: Text('Нет доступа к фотоотчётам')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Фотоотчёт',
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshTrainingOptions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrainingSelector(user?.isTrainer == true),
              _buildTrainingTypeBanner(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Комментарий',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoSection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _isSubmitting ? 'Отправка...' : _submitButtonText,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: (_isSubmitting || _isTrainingLocked)
                      ? null
                      : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSelector(bool isTrainer) {
    final trainings = _filteredTrainings;
    final dropdownValue = trainings.any((t) => t.id == _selectedTrainingId)
        ? _selectedTrainingId
        : trainings.isNotEmpty
            ? trainings.first.id
            : null;

      if (dropdownValue != null && dropdownValue != _selectedTrainingId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedTrainingId = dropdownValue;
            });
          }
        });
      }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тренировка',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isLoadingTrainings && !_trainingsInitialized)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (trainings.isEmpty)
          _buildEmptyTrainingsState(isTrainer)
        else
          InputDecorator(
            decoration: _trainingDropdownDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownValue ?? trainings.first.id,
                isExpanded: true,
                items: trainings
                    .map(
                      (schedule) => DropdownMenuItem(
                        value: schedule.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(schedule.groupName),
                            Text(
                              '${schedule.startTime} - ${schedule.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedTrainingId = value;
                  });
                  _loadLatestReportsFor(value);
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        if (_selectedTrainingId != null)
          _buildLatestPhotoPreview(),
      ],
    );
  }

  Widget _buildEmptyTrainingsState(bool isTrainer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.5)),
      ),
      child: Text(
        isTrainer
            ? 'Сейчас нет активных тренировок вокруг времени начала/окончания. Начните или завершите тренировку в разделе "Расписание", чтобы отправить фото.'
            : 'Нет доступных расписаний для вашего аккаунта.',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildTrainingTypeBanner() {
    final effectiveType = _effectiveType;
    final status = _selectedTrainingStatus;
    final hasAfter = _latestAfterReport != null;
    final hasBefore = _latestBeforeReport != null &&
        effectiveType == 'training_before';
    String title;
    String description;
    IconData icon;
    Color color;

    if (_selectedTrainingId == null ||
        !_todayTrainings.any((t) => t.id == _selectedTrainingId)) {
      title = 'Выберите тренировку';
      description =
          'Выберите расписание тренировки, чтобы отправить фотоотчёт.';
      icon = Icons.info_outline;
      color = Colors.grey.shade600;
    } else if (hasAfter) {
      title = 'Фото ПОСЛЕ загружено';
      description = 'Спасибо! Отчёт сохранён. Выберите следующую тренировку.';
      icon = Icons.verified;
      color = Colors.teal.shade700;
    } else if (effectiveType == 'training_after') {
      title = 'Фото ПОСЛЕ тренировки';
      description =
          'Тренировка завершена — загрузите итоговое фото в течение 7 минут после окончания.';
      icon = Icons.flag;
      color = Colors.green.shade700;
    } else if (hasBefore) {
      title = 'Фото ДО загружено';
      description = 'Фото ДО зафиксировано. Ожидайте завершения тренировки.';
      icon = Icons.verified;
      color = Colors.teal.shade700;
    } else {
      title = 'Фото ДО тренировки';
      description =
          'Сделайте снимок зала минимум за 10 минут до начала и загрузите его перед стартом.';
      icon = Icons.camera_alt_outlined;
      color = Colors.orange.shade700;
    }

    if (status == TrainingSessionStatus.started &&
        effectiveType == 'training_before') {
      description =
          'Тренировка уже начата. Перед следующей тренировкой добавьте фото ДО заранее.';
    }

    if (hasAfter) {
      description =
          'Фото ПОСЛЕ уже отправлено. Можете перейти к следующей тренировке.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestPhotoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Последние фото за сегодня для выбранной тренировки',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingLatestReports)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (_latestBeforeReport == null && _latestAfterReport == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Фото за сегодня ещё не загружались.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else ...[
          if (_latestBeforeReport != null)
            _LatestPhotoCard(
              title: 'Фото ДО тренировки',
              report: _latestBeforeReport!,
              urlBuilder: _photoUrl,
            ),
          if (_latestAfterReport != null)
            _LatestPhotoCard(
              title: 'Фото ПОСЛЕ тренировки',
              report: _latestAfterReport!,
              urlBuilder: _photoUrl,
            ),
        ],
      ],
    );
  }

  String? _resolveRelatedId() {
    if (_selectedType.startsWith('training')) {
      return _selectedTrainingId;
    }
    if (_selectedType == 'cleaning') {
      final cleaning = _cleaningReportController.text.trim();
      return cleaning.isEmpty ? null : cleaning;
    }
    return null;
  }

  String get _effectiveType {
    if (_selectedType.startsWith('training')) {
      return _resolveTrainingTypeForStatus();
    }
    return _selectedType;
  }

  bool get _isTrainingLocked {
    if (!_selectedType.startsWith('training')) return false;
    if (_effectiveType == 'training_before') {
      return _latestBeforeReport != null;
    }
    return _latestAfterReport != null;
  }

  String _resolveTrainingTypeForStatus() {
    if (_selectedTrainingId == null) return 'training_before';
    final status = _selectedTrainingStatus;
    if (status == TrainingSessionStatus.finished) {
      return 'training_after';
    }
    return 'training_before';
  }

  TrainingSessionStatus? get _selectedTrainingStatus {
    if (_selectedTrainingId == null) return null;
    return _sessionStatuses[_selectedTrainingId!];
  }

  Future<void> _refreshTrainingOptions() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _isLoadingTrainings = true;
    });

    try {
      final groups = await _groupService.getAllGroups();
      final myGroupIds = groups
          .where((group) =>
              (group.trainerId != null && group.trainerId == user.id) ||
              (user.isTrainer && group.trainerName == user.fullName))
          .map((group) => group.id)
          .toSet();

      final schedules = await _scheduleService.getAllSchedules();
      final todayIndex = _today.weekday - 1;
      final filtered = schedules.where((schedule) {
        if (schedule.dayOfWeek != todayIndex) return false;
        if (user.isTrainer) {
          return myGroupIds.contains(schedule.groupId);
        }
        if (user.hasRole('director') || user.isAdmin == true) {
          return myGroupIds.isEmpty
              ? true
              : myGroupIds.contains(schedule.groupId);
        }
        return false;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));


      final statuses = filtered.isEmpty
          ? <String, TrainingSessionStatus>{}
          : await _sessionService.getStatuses(
              filtered.map((s) => s.id).toList(),
              _today,
            );

      if (!mounted) return;
      setState(() {
        _todayTrainings = filtered;
        _sessionStatuses = statuses;
        _trainingsInitialized = true;
      });

      if (filtered.isEmpty) {
        setState(() {
          _selectedTrainingId = null;
          _latestBeforeReport = null;
          _latestAfterReport = null;
        });
        return;
      }

      final preselected = _pendingInitialScheduleId;
      if (preselected != null &&
          filtered.any((schedule) => schedule.id == preselected)) {
        setState(() {
          _selectedTrainingId = preselected;
          _pendingInitialScheduleId = null;
          _latestBeforeReport = null;
          _latestAfterReport = null;
        });
        _loadLatestReportsFor(preselected);
      } else if (_selectedTrainingId != null &&
          filtered.any((schedule) => schedule.id == _selectedTrainingId)) {
        _loadLatestReportsFor(_selectedTrainingId!);
      } else if (filtered.isNotEmpty) {
        final firstId = filtered.first.id;
        setState(() {
          _selectedTrainingId = firstId;
          _latestBeforeReport = null;
          _latestAfterReport = null;
        });
        _loadLatestReportsFor(firstId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось обновить расписание: $e'),
        ),
      );
      setState(() {
        _todayTrainings = [];
        _sessionStatuses = {};
        _trainingsInitialized = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrainings = false;
        });
      }
    }
  }

  Future<void> _loadLatestReportsFor(String scheduleId) async {
    if (!_selectedType.startsWith('training')) {
      return;
    }
    setState(() {
      _isLoadingLatestReports = true;
      _latestReportsScheduleId = scheduleId;
    });

    try {
      final date = _now;
      final before = await _service.getLatestReport(
        type: 'training_before',
        relatedId: scheduleId,
        date: date,
      );
      final after = await _service.getLatestReport(
        type: 'training_after',
        relatedId: scheduleId,
        date: date,
      );
      if (!mounted) return;
      if (_latestReportsScheduleId == scheduleId) {
        setState(() {
          _latestBeforeReport = before;
          _latestAfterReport = after;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (_latestReportsScheduleId == scheduleId) {
        setState(() {
          _latestBeforeReport = null;
          _latestAfterReport = null;
        });
      }
    } finally {
      if (mounted && _latestReportsScheduleId == scheduleId) {
        setState(() {
          _isLoadingLatestReports = false;
        });
      }
    }
  }

  List<ScheduleModel> get _filteredTrainings {
    if (!_selectedType.startsWith('training')) return const <ScheduleModel>[];
    final now = _now;
    final filtered = _todayTrainings.where((schedule) {
      final status =
          _sessionStatuses[schedule.id] ?? TrainingSessionStatus.notStarted;
      if (_selectedType == 'training_before') {
        return status == TrainingSessionStatus.notStarted &&
            _isWithinBeforeWindow(schedule, now);
      }
      if (_selectedType == 'training_after') {
        return _isWithinAfterWindow(schedule, now, status);
      }
      return true;
    }).toList();

    if (filtered.isNotEmpty) return filtered;
    // Если окна не совпали, показываем все сегодняшние тренировки,
    // чтобы можно было выбрать нужную вручную.
    return List<ScheduleModel>.from(_todayTrainings);
  }

  DateTime _combineTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      _today.year,
      _today.month,
      _today.day,
      hour,
      minute,
    );
  }

  bool _isWithinBeforeWindow(ScheduleModel schedule, DateTime now) {
    final start = _combineTime(schedule.startTime);
    final windowStart = start.subtract(const Duration(minutes: 10));
    final windowEnd = start.add(const Duration(minutes: 5));
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  bool _isWithinAfterWindow(
    ScheduleModel schedule,
    DateTime now,
    TrainingSessionStatus status,
  ) {
    if (status != TrainingSessionStatus.finished) {
      return false;
    }
    final end = _combineTime(schedule.endTime);
    final finishDeadline = end.add(const Duration(hours: 1));
    return now.isBefore(finishDeadline);
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Фото',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _isTrainingLocked ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Фото не добавлены')),
          )
        else
          GridView.builder(
            itemCount: _images.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final image = _images[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover)
                        : Image.file(File(image.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => setState(() {
                        _images.removeAt(index);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _cleaningReportController.dispose();
    super.dispose();
  }

  static DateTime get _now => DateTime.now().toUtc().add(const Duration(hours: 5));

  String _photoUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = ApiConfig.baseUrl.replaceFirst('/api', '');
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$normalized';
  }

  InputDecoration get _trainingDropdownDecoration => InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );

  String get _submitButtonText {
    if (_isTrainingLocked) {
      return 'Фото загружено';
    }
    final type = _effectiveType;
    switch (type) {
      case 'training_before':
        return 'Отправить фото ДО';
      case 'training_after':
        return 'Отправить фото ПОСЛЕ';
      case 'cleaning':
        return 'Отправить отчёт';
      default:
        return 'Отправить';
    }
  }
}

class _LatestPhotoCard extends StatelessWidget {
  final String title;
  final PhotoReportModel report;
  final String Function(String) urlBuilder;

  const _LatestPhotoCard({
    required this.title,
    required this.report,
    required this.urlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final photoPath = report.photos.isNotEmpty ? report.photos.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (photoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  urlBuilder(photoPath),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    alignment: Alignment.center,
                    color: AppColors.grey.withValues(alpha: 0.1),
                    child: const Text('Не удалось загрузить фото'),
                  ),
                ),
              )
            else
              const Text('Фото отсутствует'),
            const SizedBox(height: 6),
            Text(
              'Автор: ${report.authorName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              'Время: ${DateFormat('dd.MM HH:mm').format(report.createdAt.toLocal())}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
