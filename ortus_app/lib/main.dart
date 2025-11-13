import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart'; // ❌ УДАЛИТЕ ЭТУ СТРОКУ
// import 'providers/auth_provider_v2.dart'; // ✅ ОСТАВЬТЕ ТОЛЬКО ЭТУ
import 'screens/splash_screen.dart';
import 'screens/manage_products_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_requests_screen.dart';
import 'screens/create_schedule_screen.dart';
import 'utils/constants.dart';
import 'screens/mark_attendance_screen.dart';
import 'screens/news_feed_screen.dart';
// import 'screens/news_detail_screen.dart';
// import 'screens/create_news_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/attendance_analytics_admin_screen.dart';
import 'screens/groups_comparison_screen.dart';
import 'screens/create_user_screen.dart';
import 'screens/manager/pending_students_screen.dart';
import 'widgets/app_navigator.dart';
import 'screens/photo_reports/photo_report_screen.dart';
import 'screens/photo_reports/photo_reports_gallery_screen.dart';
import 'screens/cleaning/cleaning_report_screen.dart';
import 'screens/cleaning/cleaning_history_screen.dart';
import 'screens/manager/create_student_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // ✅ ЗАМЕНИТЕ AuthProvider на AuthProviderV2
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => const AppNavigator(),
        '/app': (context) => const AppNavigator(),
        '/profile': (context) => ProfileScreen(),
        '/create-group': (context) => CreateGroupScreen(),
        '/group-requests': (context) => GroupRequestsScreen(),
        '/create-schedule': (context) => CreateScheduleScreen(),
        '/news': (context) => const NewsFeedScreen(),
        '/mark-attendance': (context) => MarkAttendanceScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/attendance-analytics-admin': (context) =>
            const AttendanceAnalyticsAdminScreen(),
        '/groups-comparison': (context) => const GroupComparisonScreen(),
        '/manage-products': (context) => const ManageProductsScreen(),
        '/create-user': (context) => const CreateUserScreen(),
        '/pending-students': (context) => const PendingStudentsScreen(),
        '/create-student': (context) => const CreateStudentScreen(),
        '/photo-report': (context) => const PhotoReportScreen(),
        '/photo-reports-gallery': (context) =>
            const PhotoReportsGalleryScreen(),
        '/cleaning-report': (context) => const CleaningReportScreen(),
        '/cleaning-history': (context) => const CleaningHistoryScreen(),
      },
    );
  }
}
