import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/result_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/fees_due_screen.dart';
import '../screens/changepassword_screen.dart';
import '../screens/feedback&query_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/result':
        return MaterialPageRoute(builder: (_) => const ExamsScreen());
      case '/timetable':
        return MaterialPageRoute(builder: (_) => TimetableScreen());
      case '/attendance':
        return MaterialPageRoute(builder: (_) => const AttendanceScreen());
      case '/fees_due':
        return MaterialPageRoute(builder: (_) => FeesScreen());
      case '/change_password':
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());
      case '/feedback':
        return MaterialPageRoute(builder: (_) => FeedbackPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
