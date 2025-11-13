import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import 'financial_analytics_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'attendance_analytics_admin_screen.dart';
import 'groups_comparison_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>?> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = AnalyticsService().getDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Дашборд', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboard(),
        color: AppColors.primary,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Нет данных'));
            }

            final data = snapshot.data!;
            final overview = data['overview'];
            final currentMonth = data['currentMonth'];
            final recentAttendance = data['recentAttendance'];
            final highlights = data['highlights'] ?? {};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                const Text(
                  'Быстрая статистика',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildOverviewCards(overview),
                const SizedBox(height: 24),
                _buildCurrentMonthCard(currentMonth),
                const SizedBox(height: 20),
                _buildRecentAttendanceCard(recentAttendance),
                const SizedBox(height: 24),
                _buildHighlights(highlights),
                const SizedBox(height: 24),
                const Text(
                  'Детальная аналитика',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAnalyticsButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: AppColors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Панель управления',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Обзор ключевых показателей',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                'Студенты',
                '${overview['totalStudents']}',
                Icons.school,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                'Группы',
                '${overview['totalGroups']}',
                Icons.group,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                'Тренеры',
                '${overview['totalTrainers']}',
                Icons.sports_martial_arts,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                'Долги',
                '${overview['unpaidPayments']}',
                Icons.payment,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                'Pending студенты',
                '${overview['pendingStudents']}',
                Icons.timelapse,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                'Заказы в ожидании',
                '${overview['pendingOrders']}',
                Icons.shopping_cart,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlights(Map<String, dynamic> highlights) {
    final topGroups = List<Map<String, dynamic>>.from(
      highlights['topGroupsByAttendance'] ?? [],
    );
    final topTrainers = List<Map<String, dynamic>>.from(
      highlights['topTrainersByPhotoReports'] ?? [],
    );
    final latestReports = List<Map<String, dynamic>>.from(
      highlights['latestPhotoReports'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Топ показатели',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: 'Топ-3 группы по посещаемости',
          icon: Icons.groups,
          color: Colors.green,
          items: topGroups.map((item) {
            final rate = (item['attendanceRate'] ?? 0).toStringAsFixed(1);
            return '${item['groupName']} — $rate%';
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: 'Топ-3 тренера по фотоотчётам',
          icon: Icons.camera_alt,
          color: Colors.blue,
          items: topTrainers.map((item) {
            return '${item['trainerName']} — ${item['reports']} отчётов';
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: 'Последние фотоотчёты',
          icon: Icons.photo_library,
          color: Colors.purple,
          items: latestReports.map((item) {
            final author = item['authorId'] is Map
                ? item['authorId']['fullName']
                : 'Сотрудник';
            final type = item['type'];
            return '$author — $type';
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Данных пока нет')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthCard(Map<String, dynamic> currentMonth) {
    final revenue = currentMonth['revenue'];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Доход текущего месяца',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${revenue.toStringAsFixed(0)} ₸',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'От абонементов',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAttendanceCard(Map<String, dynamic> recentAttendance) {
    final total = recentAttendance['total'];
    final present = recentAttendance['present'];
    final rate = double.parse(recentAttendance['rate'].toString());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Посещаемость (7 дней)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Присутствовало',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$present из $total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(rate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(rate),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsButtons() {
    final user = context.watch<AuthProvider>().user;
    final isDirector = user?.hasRole('director') == true;
    final isAdminOnly = user?.isAdmin == true;
    return Column(
      children: [
        if (isDirector) ...[
          _buildAnalyticsButton(
            'Создать аккаунт',
            'Тренер или администратор',
            Icons.person_add,
            Colors.indigo,
            () => Navigator.pushNamed(context, '/create-user'),
          ),
          const SizedBox(height: 12),
        ],
        if (isAdminOnly) ...[
          _buildAnalyticsButton(
            'Управление товарами',
            'Добавить товар в магазин',
            Icons.add_shopping_cart,
            Colors.purple,
            () => Navigator.pushNamed(context, '/manage-products'),
          ),
          const SizedBox(height: 12),
        ],
        _buildAnalyticsButton(
          'Финансовая аналитика',
          'Доходы, расходы, тренды',
          Icons.attach_money,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FinancialAnalyticsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildAnalyticsButton(
          'Аналитика посещаемости',
          'Статистика по группам и студентам',
          Icons.bar_chart,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceAnalyticsAdminScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildAnalyticsButton(
          'Сравнение групп',
          'Доходы и посещаемость по группам',
          Icons.compare_arrows,
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GroupComparisonScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 85) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }
}
