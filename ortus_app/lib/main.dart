import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart'; // ❌ УДАЛИТЕ ЭТУ СТРОКУ
// import 'providers/auth_provider_v2.dart'; // ✅ ОСТАВЬТЕ ТОЛЬКО ЭТУ
import 'screens/splash_screen.dart';
import 'screens/create_product_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_requests_screen.dart';
import 'screens/create_schedule_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/payment_stats_screen.dart';
import 'utils/constants.dart';
import 'screens/mark_attendance_screen.dart';
import 'screens/news_feed_screen.dart';
// import 'screens/news_detail_screen.dart';
// import 'screens/create_news_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/attendance_analytics_admin_screen.dart';
import 'screens/groups_comparison_screen.dart';
import 'screens/create_user_screen.dart';

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
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/create-group': (context) => CreateGroupScreen(),
        '/group-requests': (context) => GroupRequestsScreen(),
        '/create-schedule': (context) => CreateScheduleScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
        '/payments': (context) => PaymentsScreen(),
        '/payment-stats': (context) => PaymentStatsScreen(),
        '/news': (context) => const NewsFeedScreen(),
        '/mark-attendance': (context) => MarkAttendanceScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/attendance-analytics-admin': (context) =>
            const AttendanceAnalyticsAdminScreen(),
        '/groups-comparison': (context) => const GroupComparisonScreen(),
        '/create-product': (context) => const CreateProductScreen(),
        '/create-user': (context) => const CreateUserScreen(),
      },
    );
  }
}
