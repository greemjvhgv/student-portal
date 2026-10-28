import 'package:flutter/material.dart';

import '../models/timetable_entry.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

/// Owner: Charleen. The student's weekly timetable (US01), read from the
/// phone's local database, so it also works offline. Each slot shows the
/// day, time and venue, with the class type as a chip.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  Future<List<TimetableEntry>> _entriesFuture = LocalDbService.instance
      .getTimetable();

  @override
  void initState() {
    super.initState();
    SyncService.instance.changes.addListener(_reload);
  }

  @override
  void dispose() {
    SyncService.instance.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _entriesFuture = LocalDbService.instance.getTimetable());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: FutureBuilder<List<TimetableEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load the timetable from this device.'),
            );
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
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
                      entry.venue == null
                          ? '${entry.day} at ${entry.time}'
                          : '${entry.day} at ${entry.time} \u2022 ${entry.venue}',
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
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
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
