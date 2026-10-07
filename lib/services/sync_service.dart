/// Owner: Annuschka (you) — local database + sync client.
///
/// Talks to the FastAPI backend's endpoints (see docs/API_CONTRACT.md) and
/// reconciles them with LocalDbService's cached/pending data. Mirrors the
/// server-side Sync Service Broker in backend/app/services/sync_service.py
/// (Ofentse).
///
/// TODO, once `http` is in pubspec.yaml (see root README):
///   - checkConnectivity() — likely via the `connectivity_plus` package
///   - pushPendingChanges() — read LocalDbService's pending_sync table,
///     POST each to /sync/push, and on each response, either clear that
///     row (synced) or surface it as a conflict (ConflictResolutionScreen)
///   - pullLatest() — GET /sync/pull/{student_id}, write results into
///     LocalDbService
///   - call both from a "Sync Now" button (SyncStatusScreen) and
///     automatically on reconnect (a connectivity listener)
class SyncService {
  // Real device over USB + `adb reverse tcp:8000 tcp:8000`: 127.0.0.1.
  // Android EMULATOR only (not used for this project per the README, but
  // noted in case someone switches): 10.0.2.2.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // TODO: implement using package:http once it's added to pubspec.yaml.
}
