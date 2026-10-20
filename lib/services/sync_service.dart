import 'package:flutter/foundation.dart';

import '../models/pending_change.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'local_db_service.dart';

/// Owner: Annuschka (sync client).
///
/// The outcome of one sync, shown on the Sync Status screen.
class SyncResult {
  const SyncResult({
    this.pushed = 0,
    this.discarded = 0,
    this.conflicts = const [],
    this.contactedServer = false,
    this.error,
  });

  /// Queued changes the server accepted.
  final int pushed;

  /// Queued grade queries the server would reject (reason under 10
  /// characters, or flagged before the grades were synced, so without a
  /// grade_id). They are dropped, so they can't block the rest of the queue.
  final int discarded;

  /// Changes the server rejected because its version was newer (FR12,
  /// FR13): {"id", "label", "server_updated_at"}.
  final List<Map<String, dynamic>> conflicts;

  final bool contactedServer;
  final String? error;

  bool get succeeded => error == null;

  String get summary {
    final waitingNote = discarded > 0
        ? ' $discarded invalid grade quer${discarded == 1 ? 'y was' : 'ies were'} removed – please flag again.'
        : '';
    if (!contactedServer) return 'Nothing to send.$waitingNote';
    return 'Synced – $pushed change${pushed == 1 ? '' : 's'} sent, latest data downloaded.$waitingNote';
  }
}

/// Sends the offline queue to the server, then downloads the student's
/// latest data (FR7–FR10). Runs when the student taps "Sync now" and
/// automatically when the phone comes back online (FR7). Conflicts follow
/// the server-wins timestamp rule, decided by the backend (FR11–FR13).
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  /// Bumped after every sync or local change, so screens reload their data.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  bool _isSyncing = false;
  bool _started = false;

  /// Starts auto-sync on reconnect. Called once, from main.dart.
  void start() {
    if (_started) return;
    _started = true;
    ConnectivityService.instance.isOnline.addListener(() {
      if (ConnectivityService.instance.isOnline.value) syncNow();
    });
  }

  void notifyLocalChange() => changes.value++;

  /// A grade query needs the server's grade_id (entity_id > 0) and a
  /// reason of at least 10 characters (schemas/grade_query.py).
  static bool _isInvalidGradeQuery(PendingChange change) =>
      change.entityType == 'grade_queries' &&
      (change.entityId <= 0 ||
          ((change.payload['reason'] as String?)?.trim().length ?? 0) < 10);

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
      // The server rejects the whole push if one grade query is invalid,
      // so drop those here instead of retrying them forever.
      final invalid = pending.where(_isInvalidGradeQuery).toList();
      for (final change in invalid) {
        await db.markChangeDiscarded(change.syncId);
      }
      final pushable = pending.where((c) => !invalid.contains(c)).toList();
      final conflicts = <Map<String, dynamic>>[];
      // Files of accepted submissions: assignment id -> path on the phone.
      final uploads = <int, String>{};
      var pushed = 0;
      var contacted = false;
      String? error;

      if (pushable.isNotEmpty) {
        try {
          final response = await ApiService.instance.pushChanges([
            for (final change in pushable)
              if (change.entityType == 'grade_queries')
                {
                  'table': 'grade_queries',
                  'id': change.entityId,
                  'status': 'pending',
                  'reason': change.payload['reason'],
                  'client_updated_at': change.payload['client_updated_at'],
                }
              else
                {
                  'table': 'assignments',
                  'id': change.entityId,
                  'status': change.payload['status'],
                  'client_updated_at': change.payload['client_updated_at'],
                },
          ]);
          contacted = true;
          // Conflicts reported by the server, by table and id (server wins).
          final serverConflicts = {
            for (final c in response['conflicts'] as List? ?? const [])
              '${(c as Map)['table']}:${c['id']}': c,
          };
          for (final change in pushable) {
            final serverConflict =
                serverConflicts['${change.entityType}:${change.entityId}'];
            if (serverConflict != null) {
              await db.markChangeConflict(change.syncId);
              conflicts.add({
                'id': change.entityId,
                'label': change.label,
                'server_updated_at': serverConflict['server_updated_at'],
              });
            } else {
              await db.markChangeSynced(change.syncId);
              if (change.entityType == 'assignments') {
                await db.setAssignmentStatus(change.entityId, 'submitted');
                final filePath = change.payload['file_path'] as String?;
                if (filePath != null) uploads[change.entityId] = filePath;
              }
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

      // Pull after the push, so the downloaded data already includes it.
      final studentId = await AuthService.getStudentId();
      if (studentId != null) {
        try {
          await db.saveServerSnapshot(
            await ApiService.instance.pullChanges(studentId),
          );
          contacted = true;
        } on ApiException catch (e) {
          error ??= 'Could not download the latest data: ${e.message}';
        }
      }

      // Upload the files last: the pull gave us each submission_id.
      for (final upload in uploads.entries) {
        final submissionId = (await db.getAssignment(upload.key))?.submissionId;
        if (submissionId == null) continue;
        try {
          await ApiService.instance.uploadSubmissionFile(
            submissionId,
            upload.value,
          );
        } on Exception catch (e) {
          error ??=
              'Submitted, but the file was not uploaded ($e) – use "Replace file".';
        }
      }

      if (contacted) {
        await db.setMeta(
          'last_synced_at',
          DateTime.now().toUtc().toIso8601String(),
        );
      }
      return SyncResult(
        pushed: pushed,
        discarded: invalid.length,
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
