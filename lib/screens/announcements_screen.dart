import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'announcement_detail_screen.dart';

/// Displays a list of announcements using sample placeholder data.
/// Tapping an item opens the AnnouncementDetailScreen.
class AnnouncementsScreen extends StatelessWidget {
  final List<Announcement> announcements;

  AnnouncementsScreen({
    super.key,
    List<Announcement>? announcements,
  }) : announcements = announcements ??
            [
              Announcement(
                title: 'Deliverable 3 due 4 Sept',
                body:
                    'Please ensure all Deliverable 3 submissions, code repositories, and documentation are uploaded prior to 4 Sept.',
                postedAt: DateTime.parse('2026-09-04'),
              ),
              Announcement(
                title: 'Portal maintenance',
                body: 'Sat 10pm',
                postedAt: DateTime.parse('2026-09-28'),
              ),
              Announcement(
                title: 'New study guide uploaded',
                body:
                    'The updated study guide for ITMDA3-34 is now available on the portal. Please download the revised version for upcoming assessments.',
                postedAt: DateTime.parse('2026-10-01'),
              ),
              Announcement(
                title: 'Exam Schedule Published',
                body:
                    'The final timetable for end-of-semester examinations is now available on the portal. Please review your exam dates and room allocations carefully.',
                postedAt: DateTime.parse('2026-10-04'),
              ),
            ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: announcements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                final formattedDate =
                    announcement.postedAt.toIso8601String().split('T')[0];

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.campaign),
                    ),
                    title: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                        ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailScreen(
                            announcement: announcement,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  /// Builds a friendly empty state when no announcements exist.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Announcements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are currently no announcement notices to display.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

