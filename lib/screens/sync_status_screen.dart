import 'package:flutter/material.dart';

import '../models/pending_change.dart';
import '../services/connectivity_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/time_format.dart';
import '../widgets/portal_app_bar.dart';

/// Sync Status (D3 Figure 6, US11): live connection card, the real offline
/// queue from the local database ("Pending items"), recently synced items,
/// and a manual "Sync Now" (FR14). Refreshes after every sync, and shows
/// the "Conflict Resolved" pop-up (Figure 8) when the server's newer
/// version wins (FR12).
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  static const _navy = PortalAppBar.navy;
  static const _queueFill = Color(0xFFF4F9FC);
  static const _queueBorder = Color(0xFF81D4FA);
  static const _blueText = Color(0xFF29B6F6);
  static const _syncedFill = Color(0xFFF4F7FA);
  static const _syncedBorder = Color(0xFFB0C4DE);

  late Future<List<PendingChange>> _pendingFuture;
  late Future<List<PendingChange>> _syncedFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    SyncService.instance.changes.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    SyncService.instance.changes.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _loadQueue() {
    _pendingFuture = LocalDbService.instance.getPendingChanges();
    _syncedFuture = LocalDbService.instance.getRecentlySynced();
  }

  /// Reloads the lists whenever a sync finishes or the queue changes.
  void _onSyncChanged() {
    if (mounted) setState(_loadQueue);
  }

  /// Manual sync (US11): explains when offline and shows a short summary.
  /// Conflicts get the "Conflict Resolved" pop-up (Fig 8) from main.dart,
  /// for manual and automatic syncs alike.
  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    final result = await SyncService.instance.syncNow();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    if (result.conflicts.isNotEmpty) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.error ?? result.summary)));
  }

  Widget _statusCard(bool isOnline) {
    final fill = isOnline ? const Color(0xFFEFFAF1) : const Color(0xFFFFF1F1);
    final border = isOnline ? const Color(0xFF81C784) : const Color(0xFFFF8A8A);
    final dot = isOnline ? const Color(0xFF4CD964) : const Color(0xFFD32F2F);
    final text = isOnline ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 3),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 28, color: dot),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                Text(
                  isOnline ? 'Ready to sync' : 'Sync will resume automatically',
                  style: TextStyle(fontSize: 16, color: text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(String title, String subtitle, Color fill, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, color: _navy)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: _blueText),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _navy,
        ),
      ),
    );
  }

  String _pendingSubtitle(PendingChange change) {
    final retries = change.attempts == 0
        ? ''
        : ' \u2022 ${change.attempts} failed attempt${change.attempts == 1 ? '' : 's'}';
    return 'Queued ${timeAgo(change.createdAt)}$retries';
  }

  String _syncedSubtitle(PendingChange change) {
    final when = timeAgo(change.syncedAt ?? change.createdAt);
    return change.status == 'conflict'
        ? 'Conflict – server version kept ($when)'
        : 'Synced $when';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Sync Status'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService.instance.isOnline,
              builder: (context, isOnline, _) => _statusCard(isOnline),
            ),
            FutureBuilder<List<PendingChange>>(
              future: _pendingFuture,
              builder: (context, snapshot) {
                final pending = snapshot.data ?? const <PendingChange>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading('Pending items (${pending.length})'),
                    if (pending.isEmpty)
                      const Text(
                        'Nothing waiting – all your changes have been sent.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    for (final change in pending)
                      _itemCard(
                        change.label,
                        _pendingSubtitle(change),
                        _queueFill,
                        _queueBorder,
                      ),
                  ],
                );
              },
            ),
            FutureBuilder<List<PendingChange>>(
              future: _syncedFuture,
              builder: (context, snapshot) {
                final synced = snapshot.data ?? const <PendingChange>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading('Recently synced'),
                    if (synced.isEmpty)
                      const Text(
                        'Nothing synced yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    for (final change in synced)
                      _itemCard(
                        change.label,
                        _syncedSubtitle(change),
                        _syncedFill,
                        _syncedBorder,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                height: 52,
                width: 240,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isSyncing ? null : _syncNow,
                  child: _isSyncing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sync Now'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
