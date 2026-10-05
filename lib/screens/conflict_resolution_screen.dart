import 'package:flutter/material.dart';

/// Matches the Conflict Resolution modal (D3 Figure 8) shown over Sync
/// Status when the backend reports a conflict on POST /sync/push: explains
/// which version won (server, if more recent — FR12/US03/US06) and why.
///
/// Owner: Annuschka (you). TODO:
///   - show as a modal/dialog triggered from SyncStatusScreen when
///     /sync/push's response has a non-empty "conflicts" array
///   - "View Record" navigates to the affected screen (e.g. GradesScreen);
///     "Dismiss" closes the modal
class ConflictResolutionScreen extends StatelessWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve Sync Conflict')),
      body: const Center(
        child: Text('TODO: show conflicting versions + resolution outcome'),
      ),
    );
  }
}
