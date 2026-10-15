import 'package:flutter/material.dart';
import 'screens/assignments_screen.dart';
import 'screens/course_materials_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sync_status_screen.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService.instance.start();
  SyncService.instance.start();
  runApp(const StudentPortalApp());
}

class StudentPortalApp extends StatelessWidget {
  const StudentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Portal',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      initialRoute: '/login',
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