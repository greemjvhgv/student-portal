import 'package:flutter/material.dart';

/// Matches the Sync Status wireframe (D3 Figure 6): connectivity banner,
/// "Pending items" list (with queued timestamps), "Recently synced" list,
/// manual "Sync Now" button.
///
/// Owner: Annuschka (you). Follow login_screen.dart's shape. TODO:
///   - read the pending_sync queue from LocalDbService
///   - "Sync Now" calls SyncService.pushPending() + pullLatest(), disabled
///     while offline (US11)
class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: const Center(
        child: Text('TODO: connectivity indicator, pending/synced queues'),
      ),
    );
  }
}
