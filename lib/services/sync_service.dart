import 'package:flutter/foundation.dart';
import 'api_service.dart';
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
    return 'Synced $pushed item${pushed == 1 ? '' : 's'}.$waitingNote';
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
    final pending = await db.getPendingChanges();
    final pushable = pending.where((c) => c.entityType == 'assignments').toList();
    final waiting = pending.length - pushable.length;
    var contacted = false;

    try {
      var conflicts = <Map<String, dynamic>>[];
      if (pushable.isNotEmpty) {
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
        final conflictIds = {
          for (final c in response['conflicts'] as List? ?? const []) (c as Map)['id'],
        };
        for (final change in pushable) {
          if (conflictIds.contains(change.entityId)) {
            await db.markChangeConflict(change.syncId);
            conflicts.add({'id': change.entityId, 'label': change.label});
          } else {
            await db.markChangeSynced(change.syncId);
            await db.setAssignmentStatus(change.entityId, 'submitted');
          }
        }
      }

      final studentId = await db.getMeta('student_id');
      if (studentId != null) {
        await db.saveServerSnapshot(
          await ApiService.instance.pullChanges(int.parse(studentId)),
        );
        contacted = true;
      }

      if (contacted) {
        await db.setMeta('last_synced_at', DateTime.now().toUtc().toIso8601String());
      }
      return SyncResult(
        pushed: pushable.length - conflicts.length,
        waiting: waiting,
        conflicts: conflicts,
        contactedServer: contacted,
      );
    } on ApiException catch (e) {
      for (final change in pushable) {
        await db.recordFailedAttempt(change.syncId);
      }
      return SyncResult(waiting: waiting, error: e.message);
    } finally {
      _isSyncing = false;
      notifyLocalChange();
    }
  }
}