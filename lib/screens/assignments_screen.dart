import 'package:flutter/material.dart';

/// Matches the Assignment Submission wireframe (D3 Figure 7): offline
/// warning banner, assignment header, attachment drop zone, notes field,
/// submit button, "Pending in local queue" list.
///
/// Owner: Annuschka (you). Follow login_screen.dart's shape. TODO:
///   - if offline, save the submission locally via LocalDbService with
///     status "queued" (US05) instead of calling the API directly
///   - SyncService picks up queued submissions and POSTs
///     /assignments/{id}/submit once connectivity returns
class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: const Center(
        child: Text('TODO: assignment list + submission flow'),
      ),
    );
  }
}
