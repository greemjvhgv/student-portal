import 'package:flutter/material.dart';

/// Matches the Dashboard wireframe (D3 Figure 2): "Today's Timetable" card,
/// "Announcements" card, quick-link buttons, bottom nav.
///
/// Owner: Charleen (D4: frontend — timetable + announcements screens).
/// Follow login_screen.dart's shape (StatefulWidget, loading state) when
/// building this out. TODO:
///   - read from LocalDbService (lib/services/local_db_service.dart) first
///     so it works offline, matching the wireframe's "cached locally -
///     visible offline" footnote on both cards
///   - use the OfflineBadge widget (lib/widgets/offline_badge.dart) in the
///     header, per the wireframe's green "Online" status pill
///   - "My Grades" / "My Course Materials" buttons navigate to those screens
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text('TODO (Charleen): timetable + announcements cards, quick links'),
      ),
    );
  }
}
