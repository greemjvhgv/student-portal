import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../models/timetable_entry.dart';
import '../services/local_db_service.dart';
import 'announcements_screen.dart';
import 'announcement_detail_screen.dart';
import 'timetable_screen.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart';

/// Owner: Charleen. The home screen (D3 Dashboard wireframe): today's
/// timetable and the latest announcements from the local database, the
/// online/offline status, and navigation to the other screens.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Future<List<TimetableEntry>> _todayFuture = LocalDbService.instance
      .getTimetable()
      .then((entries) {
        final today = _weekdays[DateTime.now().weekday - 1];
        return entries.where((entry) => entry.day == today).toList();
      });

  final Future<List<Announcement>> _announcementsFuture = LocalDbService
      .instance
      .getAnnouncements()
      .then((list) => list.take(3).toList());

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF0B2545);
    const cardBgColor = Color(0xFFF4F7FA);
    const cardBorderColor = Color(0xFFB0C4DE);
    const buttonBgColor = Color(0xFFEEF5FC);
    const buttonBorderColor = Color(0xFF1976D2);
    const buttonTextColor = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navyColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _buildHeaderTitle(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FutureBuilder<List<TimetableEntry>>(
                      future: _todayFuture,
                      builder: (context, snapshot) => _buildTimetableCard(
                        context,
                        snapshot.data ?? const [],
                        snapshot.connectionState != ConnectionState.done,
                        navyColor,
                        cardBgColor,
                        cardBorderColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Announcement>>(
                      future: _announcementsFuture,
                      builder: (context, snapshot) => _buildAnnouncementsCard(
                        context,
                        snapshot.data ?? const [],
                        snapshot.connectionState != ConnectionState.done,
                        navyColor,
                        cardBgColor,
                        cardBorderColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      label: 'My Grades',
                      route: '/grades',
                      bgColor: buttonBgColor,
                      borderColor: buttonBorderColor,
                      textColor: buttonTextColor,
                    ),
                    const SizedBox(height: 14),
                    _buildActionButton(
                      context,
                      label: 'My Course Materials',
                      route: '/course-materials',
                      bgColor: buttonBgColor,
                      borderColor: buttonBorderColor,
                      textColor: buttonTextColor,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context, navyColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, Color navyColor) {
    return Container(
      color: navyColor,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, label: 'Home', isSelected: true, onTap: () {}),
          _buildNavItem(
            context,
            label: 'Grades',
            isSelected: false,
            onTap: () => Navigator.pushNamed(context, '/grades'),
          ),
          _buildNavItem(
            context,
            label: 'Assignments',
            isSelected: false,
            onTap: () => Navigator.pushNamed(context, '/assignments'),
          ),
          _buildNavItem(
            context,
            label: 'Sync',
            isSelected: false,
            onTap: () => Navigator.pushNamed(context, '/sync-status'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required String route,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Colors.grey),
      ),
    );
  }

  Widget _buildAnnouncementsCard(
    BuildContext context,
    List<Announcement> announcements,
    bool isLoading,
    Color navyColor,
    Color cardBgColor,
    Color cardBorderColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Announcements',
                    style: TextStyle(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            if (announcements.isEmpty)
              _cardMessage(isLoading ? 'Loading…' : 'No announcements yet'),
            ...announcements.map(
              (announcement) => InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AnnouncementDetailScreen(announcement: announcement),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u2022 ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: cardBorderColor, height: 1),
            const SizedBox(height: 6),
            const Text(
              'cached locally - visible offline',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableCard(
    BuildContext context,
    List<TimetableEntry> entries,
    bool isLoading,
    Color navyColor,
    Color cardBgColor,
    Color cardBorderColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimetableScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Today's Timetable",
                    style: TextStyle(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              _cardMessage(isLoading ? 'Loading…' : 'No classes today'),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: Text(
                  '${entry.time} ${entry.moduleCode}',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: cardBorderColor, height: 1),
            const SizedBox(height: 6),
            const Text(
              'cached locally - visible offline',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need an internet connection to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          key: const Key('logo_header'),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Icon(Icons.school, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.isOnline,
          builder: (context, isOnline, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF4CD964)
                      : const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Log out',
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _confirmLogout,
        ),
      ],
    );
  }
}
