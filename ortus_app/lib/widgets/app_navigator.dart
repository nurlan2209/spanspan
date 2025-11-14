import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/attendance_analytics_screen.dart';
import '../screens/cleaning/cleaning_history_screen.dart';
import '../screens/cleaning/cleaning_report_screen.dart';
import '../screens/director/director_staff_screen.dart';
import '../screens/director/director_students_screen.dart';
import '../screens/login_screen.dart';
import '../screens/manager/manager_groups_screen.dart';
import '../screens/manager/pending_students_screen.dart';
import '../screens/mark_attendance_screen.dart';
import '../screens/news_feed_screen.dart';
import '../screens/manage_products_screen.dart';
import '../screens/photo_reports/photo_report_screen.dart';
import '../screens/photo_reports/photo_reports_gallery_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/schedule_list_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/trainer/trainer_groups_screen.dart';
import '../screens/common/placeholder_screen.dart';
import '../utils/constants.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingAuth) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = auth.user;
        if (user == null) {
          return const LoginScreen();
        }

        final tabs = _buildTabsForUser(user);
        if (_currentIndex >= tabs.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: tabs.map((tab) => tab.widget).toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            type: BottomNavigationBarType.fixed,
            items: tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    label: tab.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  List<_TabItem> _buildTabsForUser(UserData user) {
    if (user.hasRole('director')) {
      return [
        _TabItem('Дашборд', Icons.dashboard, const AdminDashboardScreen()),
        _TabItem('Студенты', Icons.school, const DirectorStudentsScreen()),
        _TabItem('Сотрудники', Icons.badge, const DirectorStaffScreen()),
        _TabItem(
          'Фото',
          Icons.photo_library,
          const PhotoReportsGalleryScreen(),
        ),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.isAdmin) {
      return [
        _TabItem('Товары', Icons.inventory_2, const ManageProductsScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.hasRole('manager')) {
      return [
        _TabItem('Новые', Icons.person_add, const PendingStudentsScreen()),
        _TabItem('Группы', Icons.groups, const ManagerGroupsScreen()),
        _TabItem('Новости', Icons.article, const NewsFeedScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.isTrainer) {
      return [
        _TabItem(
          'Расписание',
          Icons.calendar_month,
          const ScheduleListScreen(),
        ),
        _TabItem('Посещаемость', Icons.fact_check, MarkAttendanceScreen()),
        _TabItem('Группы', Icons.groups, const TrainerGroupsScreen()),
        _TabItem('Фото', Icons.camera_alt, const PhotoReportScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.hasRole('tech_staff')) {
      return [
        _TabItem(
          'Отчёт',
          Icons.cleaning_services,
          const CleaningReportScreen(),
        ),
        _TabItem('История', Icons.history, const CleaningHistoryScreen()),
        _TabItem(
          'Расписание',
          Icons.schedule,
          const PlaceholderScreen(
            title: 'Расписание уборок',
            description:
                'Скоро здесь появится расписание уборок по зонам и датам.',
            icon: Icons.schedule,
          ),
        ),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.hasRole('parent')) {
      return [
        _TabItem(
          'Расписание',
          Icons.calendar_today,
          const ScheduleListScreen(),
        ),
        _TabItem('Новости', Icons.article, const NewsFeedScreen()),
        _TabItem(
          'Посещаемость',
          Icons.fact_check,
          const AttendanceAnalyticsScreen(),
        ),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    // default student
    return [
      _TabItem('Расписание', Icons.calendar_today, const ScheduleListScreen()),
      _TabItem('Новости', Icons.article, const NewsFeedScreen()),
      _TabItem(
        'Посещаемость',
        Icons.bar_chart,
        const AttendanceAnalyticsScreen(),
      ),
      _TabItem('Магазин', Icons.store, ShopScreen()),
      _TabItem('Профиль', Icons.person, _profileScreen()),
    ];
  }

  Widget _profileScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Профиль', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ProfileScreen(),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final Widget widget;

  const _TabItem(this.label, this.icon, this.widget);
}
