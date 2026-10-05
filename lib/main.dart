import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/sync_status_screen.dart';
import 'screens/course_materials_screen.dart';

void main() {
  runApp(const StudentPortalApp());
}

/// Owner: Annuschka (you) — repo & integration. Named routes wire the
/// wireframe screens together per the D3 User Flow diagram (Figure 9):
/// Login -> Dashboard -> Grades / Course Materials / Assignments / Sync.
/// ConflictResolutionScreen isn't routed here — it's shown as a modal from
/// SyncStatusScreen (see that file's TODO), not navigated to directly.
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
