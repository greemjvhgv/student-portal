import 'package:flutter/material.dart';

import 'screens/assignments_screen.dart';
import 'screens/conflict_resolution_screen.dart';
import 'screens/course_materials_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sync_status_screen.dart';
import 'screens/timetable_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'utils/time_format.dart';

/// Lets the app show a pop-up on top of whichever screen is open.
final navigatorKey = GlobalKey<NavigatorState>();

/// Owner: Annuschka (frontend + integration).
///
/// App entry point: starts connectivity monitoring and auto-sync, opens the
/// Dashboard if the student already logged in once (so the app works
/// offline), otherwise the Login screen, and defines the named routes.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService.instance.start();
  SyncService.instance.start();
  SyncService.instance.conflictsFound.addListener(_showConflictPopup);
  final loggedIn = await AuthService.isLoggedIn();
  runApp(StudentPortalApp(initialRoute: loggedIn ? '/dashboard' : '/login'));
}

/// Shows the "Conflict Resolved" pop-up (Fig 8, FR12, US06) after any
/// sync in which the server's newer version won, including the automatic
/// sync when the phone comes back online.
void _showConflictPopup() {
  final context = navigatorKey.currentContext;
  final conflicts = SyncService.instance.conflictsFound.value;
  if (context == null || conflicts.isEmpty) return;
  final conflict = conflicts.first;
  final serverTime = DateTime.tryParse('${conflict['server_updated_at']}');
  showConflictResolvedDialog(
    context,
    recordName: conflict['label'] as String,
    serverUpdateTime: serverTime == null ? null : clockTime(serverTime),
  );
}

class StudentPortalApp extends StatelessWidget {
  const StudentPortalApp({super.key, this.initialRoute = '/login'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Student Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/grades': (context) => const GradesScreen(),
        '/assignments': (context) => const AssignmentsScreen(),
        '/course-materials': (context) => const CourseMaterialsScreen(),
        '/sync-status': (context) => const SyncStatusScreen(),
        '/timetable': (context) => const TimetableScreen(),
      },
    );
  }
}
