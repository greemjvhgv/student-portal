import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';

/// Displays the student's scheduled class timetable using sample placeholder data.
/// Matches the API contract for GET /timetable/{student_id}.
class TimetableScreen extends StatelessWidget {
  final List<TimetableEntry> entries;

  TimetableScreen({
    super.key,
    List<TimetableEntry>? entries,
  }) : entries = entries ??
            [
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
              TimetableEntry(
                moduleCode: 'ITSEA3-34',
                day: 'Tuesday',
                time: '11:30',
                type: 'Practical',
              ),
              TimetableEntry(
                moduleCode: 'ITIOA3-34',
                day: 'Wednesday',
                time: '14:00',
                type: 'Workshop',
              ),
              TimetableEntry(
                moduleCode: 'ITIOA3-34',
                day: 'Thursday',
                time: '10:00',
                type: 'Tutorial',
              ),
            ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
      ),
      body: entries.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(
                        entry.type.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      entry.moduleCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${entry.day} at ${entry.time} • ${entry.type}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    trailing: Chip(
                      label: Text(
                        entry.type,
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Builds a friendly empty state when no timetable entries exist.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Timetable Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have no scheduled classes at this time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

