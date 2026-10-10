import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../models/timetable_entry.dart';
import 'announcements_screen.dart';
import 'announcement_detail_screen.dart';
import 'timetable_screen.dart';

/// Header bar with logo_header placeholder, "Dashboard" title, "Online" status pill,
/// "Today's Timetable" card, "Announcements" card, "My Grades" / "My Course Materials"
/// buttons, and bottom navigation bar (Home, Grades, Assignments, Sync).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF0B2545);
    const cardBgColor = Color(0xFFF4F7FA);
    const cardBorderColor = Color(0xFFB0C4DE);
    const buttonBgColor = Color(0xFFEEF5FC);
    const buttonBorderColor = Color(0xFF1976D2);
    const buttonTextColor = Color(0xFF0D47A1);

    final timetablePreview = [
      TimetableEntry(
        moduleCode: 'Group Project Consultation',
        day: 'Monday',
        time: '15:00',
        type: 'Meeting',
      ),
      TimetableEntry(
        moduleCode: 'ITMDA3-34',
        day: 'Monday',
        time: '18:00',
        type: 'Lecture',
      ),
    ];

    final announcementsPreview = [
      Announcement(
        title: 'Deliverable 3 due 4 Sept',
        body: 'Please ensure all Deliverable 3 submissions are uploaded prior to 4 Sept.',
        postedAt: DateTime.parse('2026-09-04'),
      ),
      Announcement(
        title: 'Portal maintenance Sat 10pm',
        body: 'The portal will undergo scheduled maintenance this Saturday at 10pm.',
        postedAt: DateTime.parse('2026-09-28'),
      ),
      Announcement(
        title: 'New study guide uploaded',
        body: 'The updated study guide for ITMDA3-34 is now available on the portal.',
        postedAt: DateTime.parse('2026-10-01'),
      ),
    ];

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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimetableCard(context, timetablePreview, navyColor, cardBgColor, cardBorderColor),
                    const SizedBox(height: 16),
                    _buildAnnouncementsCard(context, announcementsPreview, navyColor, cardBgColor, cardBorderColor),
                    const SizedBox(height: 16),
                    _buildActionButton(context, label: 'My Grades', route: '/grades', bgColor: buttonBgColor, borderColor: buttonBorderColor, textColor: buttonTextColor),
                    const SizedBox(height: 14),
                    _buildActionButton(context, label: 'My Course Materials', route: '/course-materials', bgColor: buttonBgColor, borderColor: buttonBorderColor, textColor: buttonTextColor),
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





  // Bottom Navigation Bar
  Widget _buildBottomNav(BuildContext context, Color navyColor) {
    return Container(
      color: navyColor,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, label: 'Home', isSelected: true, onTap: () {}),
          _buildNavItem(context, label: 'Grades', isSelected: false, onTap: () => Navigator.pushNamed(context, '/grades')),
          _buildNavItem(context, label: 'Assignments', isSelected: false, onTap: () => Navigator.pushNamed(context, '/assignments')),
          _buildNavItem(context, label: 'Sync', isSelected: false, onTap: () => Navigator.pushNamed(context, '/sync-status')),
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
  // Action button for Grades and Course Materials
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }
  // Announcements Card with navigation to AnnouncementsScreen
  Widget _buildAnnouncementsCard(
    BuildContext context,
    List<Announcement> announcements,
    Color navyColor,
    Color cardBgColor,
    Color cardBorderColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AnnouncementsScreen()));
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
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Announcements',
                    style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            ...announcements.map(
              (announcement) => InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementDetailScreen(announcement: announcement),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(fontSize: 15, color: Colors.black87),
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
            const Text('cached locally - visible offline', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  // Today's Timetable Card with navigation to TimetableScreen
  Widget _buildTimetableCard(
    BuildContext context,
    List<TimetableEntry> entries,
    Color navyColor,
    Color cardBgColor,
    Color cardBorderColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => TimetableScreen()));
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
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Today's Timetable",
                    style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(child: Divider(color: cardBorderColor, thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Text('${entry.time} ${entry.moduleCode}', style: TextStyle(fontSize: 15, color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: cardBorderColor, height: 1),
            const SizedBox(height: 6),
            const Text('cached locally - visible offline', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  // Header with logo_header placeholder and "Online" status pill
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(color: Color(0xFF4CD964), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('Online', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
