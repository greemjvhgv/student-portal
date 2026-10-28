import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/time_format.dart';
import '../widgets/portal_app_bar.dart';
import 'submit_assignment_screen.dart';

/// Owner: Annuschka. The student's assignments with their status (US05):
/// not submitted, queued (waiting to sync) or submitted. Read from the
/// local database, so it works offline
/// Owner: Annuschka. The student's assignments with their status (US05):
/// not submitted, queued (waiting to sync) or submitted. Read from the
/// local database, so it works offline; tapping one opens the Submit
/// Assignment screen.
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  static const _navy = PortalAppBar.navy;

  Future<List<Assignment>> _assignmentsFuture = LocalDbService.instance
      .getAssignments();

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
    setState(() {
      _assignmentsFuture = LocalDbService.instance.getAssignments();
    });
  }

  Future<void> _open(Assignment assignment) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SubmitAssignmentScreen(assignment: assignment),
      ),
    );
    _reload();
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'submitted' => ('Submitted', const Color(0xFF2E7D32)),
      'queued' => ('Queued offline', const Color(0xFFB26A00)),
      _ => ('Not submitted', const Color(0xFFD32F2F)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Assignments'),
      body: SafeArea(
        child: FutureBuilder<List<Assignment>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text('Could not load assignments from this device.'),
              );
            }
            final assignments = snapshot.data!;
            if (assignments.isEmpty) {
              return const Center(child: Text('No assignments yet.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final assignment in assignments)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.dueDate == null
                                  ? assignment.moduleCode
                                  : '${assignment.moduleCode} \u2022 Due ${formatDue(assignment.dueDate!)}',
                            ),
                            const SizedBox(height: 6),
                            _statusChip(assignment.status),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(assignment),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
