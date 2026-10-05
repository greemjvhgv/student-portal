/// Owner: Annuschka (you) — local database + sync client.
///
/// Wraps the on-device SQLite database via `sqflite`, so screens can read
/// cached data (grades, assignments, timetable, announcements) while
/// offline. This is the device-side counterpart to the backend's own
/// database (backend/app/database.py) — a separate SQLite file, on the
/// phone, reconciled by SyncService below.
///
/// TODO, once `sqflite` + `path` are in pubspec.yaml (see root README):
///   import 'package:sqflite/sqflite.dart';
///   import 'package:path/path.dart';
///
///   1. openDatabase() — create tables mirroring the API contract
///      (docs/API_CONTRACT.md): students, grades, assignments, timetable,
///      announcements, course_materials, PLUS a `pending_sync` table for
///      anything created/edited while offline (table name, record id,
///      operation type, payload, created_at — mirrors the backend's
///      SyncOperation model so the shapes match on push).
///   2. insert/update/query helpers per table, used by the screens.
///   3. a way for SyncService to read "pending_sync" rows and push them
///      when connectivity returns, and clear them once synced.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  // TODO: Database? _db;
  // Future<Database> get database async { ... }
}
