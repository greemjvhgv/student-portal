import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'local_db_service.dart';

class SyncResult {
  const SyncResult({
    this.pushed = 0,
    this.waiting = 0,
    this.conflicts = const [],
    this.contactedServer = false,
    this.error,
  });

  final int pushed;
  final int waiting;
  final List<Map<String, dynamic>> conflicts;
  final bool contactedServer;
  final String? error;

  bool get succeeded => error == null;

  String get summary {
    final waitingNote = waiting > 0
        ? ' $waiting grade quer${waiting == 1 ? 'y is' : 'ies are'} waiting until the server supports them.'
        : '';
    if (!contactedServer) return 'Nothing to send.$waitingNote';
    return 'Synced – $pushed change${pushed == 1 ? '' : 's'} sent, latest data downloaded.$waitingNote';
  }
}

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  bool _isSyncing = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    ConnectivityService.instance.isOnline.addListener(() {
      if (ConnectivityService.instance.isOnline.value) syncNow();
    });
  }

  void notifyLocalChange() => changes.value++;

  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return const SyncResult(error: 'A sync is already running.');
    }
    if (!ConnectivityService.instance.isOnline.value) {
      return const SyncResult(
        error: "You're offline – sync will resume automatically when you're back online.",
      );
    }
    _isSyncing = true;
    final db = LocalDbService.instance;

    try {
      final pending = await db.getPendingChanges();
      final pushable = pending.where((c) => c.entityType == 'assignments').toList();
      final waiting = pending.length - pushable.length;
      final conflicts = <Map<String, dynamic>>[];
      var pushed = 0;
      var contacted = false;
      String? error;

      if (pushable.isNotEmpty) {
        try {
          final response = await ApiService.instance.pushChanges([
            for (final change in pushable)
              {
                'table': 'assignments',
                'id': change.entityId,
                'status': change.payload['status'],
                'client_updated_at': change.payload['client_updated_at'],
              },
          ]);
          contacted = true;
          // Conflicts reported by the server, by record id (server wins).
          final serverConflicts = {
            for (final c in response['conflicts'] as List? ?? const [])
              (c as Map)['id']: c,
          };
          for (final change in pushable) {
            final serverConflict = serverConflicts[change.entityId];
            if (serverConflict != null) {
              await db.markChangeConflict(change.syncId);
              conflicts.add({
                'id': change.entityId,
                'label': change.label,
                'server_updated_at': serverConflict['server_updated_at'],
              });
            } else {
              await db.markChangeSynced(change.syncId);
              await db.setAssignmentStatus(change.entityId, 'submitted');
              pushed++;
            }
          }
        } on ApiException catch (e) {
          for (final change in pushable) {
            await db.recordFailedAttempt(change.syncId);
          }
          error = 'Queued changes not sent: ${e.message}';
        }
      }

      final studentId = await AuthService.getStudentId();
      if (studentId != null) {
        try {
          await db.saveServerSnapshot(await ApiService.instance.pullChanges(studentId));
          contacted = true;
        } on ApiException catch (e) {
          error ??= 'Could not download the latest data: ${e.message}';
        }
      }

      if (contacted) {
        await db.setMeta('last_synced_at', DateTime.now().toUtc().toIso8601String());
      }
      return SyncResult(
        pushed: pushed,
        waiting: waiting,
        conflicts: conflicts,
        contactedServer: contacted,
        error: error,
      );
    } finally {
      _isSyncing = false;
      notifyLocalChange();
    }
  }
}