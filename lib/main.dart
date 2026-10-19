import 'package:flutter/material.dart';
import 'screens/assignments_screen.dart';
import 'screens/course_materials_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sync_status_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService.instance.start();
  SyncService.instance.start();
  // A stored token means the student already logged in once, so open
  // straight to the dashboard (works offline too).
  final loggedIn = await AuthService.isLoggedIn();
  runApp(StudentPortalApp(initialRoute: loggedIn ? '/dashboard' : '/login'));
}

class StudentPortalApp extends StatelessWidget {
  const StudentPortalApp({super.key, this.initialRoute = '/login'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Portal',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/grades': (context) => const GradesScreen(),
        '/assignments': (context) => const AssignmentsScreen(),
        '/course-materials': (context) => const CourseMaterialsScreen(),
        '/sync-status': (context) => const SyncStatusScreen(),
      },
    );
  }
}