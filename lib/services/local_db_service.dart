import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/announcement.dart';
import '../models/assignment.dart';
import '../models/course_material.dart';
import '../models/grade.dart';
import '../models/grade_query.dart';
import '../models/pending_change.dart';
import '../models/timetable_entry.dart';

/// Owner: Annuschka (local database + sync client).
///
/// The SQLite database on the phone (sqflite). Screens read cached data
/// from here, so they keep working offline (FR2, FR4). Table and column
/// names mirror docs/API_CONTRACT.md. `pending_sync` mirrors the backend's
/// SyncOperation model and holds changes made offline until SyncService
/// pushes them (FR5, FR6). `app_meta` stores small values such as the time
/// of the last successful sync.
class LocalDbService {
  LocalDbService._internal();
  static final LocalDbService instance = LocalDbService._internal();

  static const _dbName = 'student_portal.db';

  /// Version history (each step is applied in [_onUpgrade], so data that is
  /// already on a phone is kept):
  ///   2: app_meta, pending_sync.synced_at and more sample assignments
  ///   3: assignments.submission_id, timetable.venue and grade_queries
  static const _dbVersion = 3;

  Database? _db;

  /// Opens the database the first time it is needed, then reuses it.
  Future<Database> get database async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Runs once, when the database file is first created on the phone.
  Future<void> _onCreate(Database db, int version) async {
    for (final statement in _createTables) {
      await db.execute(statement);
    }
    await _insertPlaceholderData(db);
  }

  /// Updates databases created by an older version of the app.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createAppMeta);
      await db.execute('ALTER TABLE pending_sync ADD COLUMN synced_at TEXT');
      await _insertSampleAssignments(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE assignments ADD COLUMN submission_id INTEGER',
      );
      await db.execute('ALTER TABLE timetable ADD COLUMN venue TEXT');
      await db.execute(_createGradeQueries);
    }
  }

  static const _createAppMeta =
      'CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT)';

  static const _createGradeQueries =
      'CREATE TABLE grade_queries ('
      'query_id INTEGER PRIMARY KEY, '
      'grade_id INTEGER NOT NULL, '
      'module_code TEXT, '
      'reason TEXT NOT NULL, '
      'status TEXT NOT NULL)';

  static const List<String> _createTables = [
    'CREATE TABLE grades ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'module_code TEXT NOT NULL, '
        'module_name TEXT, '
        'mark REAL, '
        'updated_at TEXT)',
    'CREATE TABLE assignments ('
        'id INTEGER PRIMARY KEY, '
        'module_code TEXT NOT NULL, '
        'title TEXT NOT NULL, '
        'status TEXT NOT NULL, '
        'due_date TEXT, '
        'submission_id INTEGER)',
    'CREATE TABLE timetable ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'module_code TEXT NOT NULL, '
        'day TEXT NOT NULL, '
        'time TEXT NOT NULL, '
        'type TEXT, '
        'venue TEXT)',
    'CREATE TABLE announcements ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'title TEXT NOT NULL, '
        'body TEXT NOT NULL, '
        'posted_at TEXT)',
    'CREATE TABLE course_materials ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'module_code TEXT NOT NULL, '
        'title TEXT NOT NULL, '
        'file_url TEXT, '
        'local_path TEXT)',
    'CREATE TABLE pending_sync ('
        'sync_id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'entity_type TEXT NOT NULL, '
        'entity_id INTEGER NOT NULL, '
        'operation_type TEXT NOT NULL, '
        'payload TEXT NOT NULL, '
        'created_at TEXT NOT NULL, '
        "status TEXT NOT NULL DEFAULT 'pending', "
        'attempts INTEGER NOT NULL DEFAULT 0, '
        'synced_at TEXT)',
    _createAppMeta,
    _createGradeQueries,
  ];

  /// TEMPORARY sample data from the D3 wireframes, shown before the first
  /// login. Replaced by the student's real data on the first sync.
  Future<void> _insertPlaceholderData(Database db) async {
    final now = DateTime.now().toUtc();
    final batch = db.batch();

    for (final grade in [
      {
        'module_code': 'ITMDA3-34',
        'module_name': 'Project - Mobile & Web Services',
        'mark': 84.0,
      },
      {
        'module_code': 'ITMTA3-33',
        'module_name': 'Calculus Mathematics',
        'mark': 72.0,
      },
      {
        'module_code': 'ITOPE3-33',
        'module_name': 'Operating Systems',
        'mark': null,
      },
    ]) {
      batch.insert('grades', {...grade, 'updated_at': now.toIso8601String()});
    }

    for (final entry in [
      {
        'module_code': 'ITMDA3-34',
        'day': 'Monday',
        'time': '15:00',
        'type': 'Consultation',
      },
      {
        'module_code': 'ITMDA3-34',
        'day': 'Monday',
        'time': '18:00',
        'type': 'Lecture',
      },
      {
        'module_code': 'ITMTA3-33',
        'day': 'Tuesday',
        'time': '11:30',
        'type': 'Practical',
      },
      {
        'module_code': 'ITOPE3-33',
        'day': 'Thursday',
        'time': '10:00',
        'type': 'Tutorial',
      },
    ]) {
      batch.insert('timetable', entry);
    }

    for (final announcement in [
      {
        'title': 'Deliverable 3 due 4 Sept',
        'body': 'Please upload all Deliverable 3 work before 4 Sept.',
        'posted_at': '2026-09-01',
      },
      {
        'title': 'Portal maintenance',
        'body': 'Saturday 10pm',
        'posted_at': '2026-09-28',
      },
      {
        'title': 'New study guide uploaded',
        'body': 'The updated ITMDA3-34 study guide is available.',
        'posted_at': '2026-10-01',
      },
    ]) {
      batch.insert('announcements', announcement);
    }

    for (final material in [
      {
        'module_code': 'ITMDA3-34',
        'title': 'Week 6 - Lecture Slides.pdf',
        'local_path': 'cached',
      },
      {
        'module_code': 'ITMDA3-34',
        'title': 'Study Guide - Databases.pdf',
        'local_path': null,
      },
      {
        'module_code': 'ITMTA3-33',
        'title': 'Week 6 - Lecture Slides.pdf',
        'local_path': 'cached',
      },
      {
        'module_code': 'ITMTA3-33',
        'title': 'Week 6 - Course Slides.pdf',
        'local_path': 'cached',
      },
      {
        'module_code': 'ITOPE3-33',
        'title': 'Week 6 - Lecture Slides.pdf',
        'local_path': 'cached',
      },
    ]) {
      batch.insert('course_materials', material);
    }

    await batch.commit(noResult: true);
    await _insertSampleAssignments(db);
  }

  /// TEMPORARY sample assignments, due 1–3 weeks from today at 23:59.
  /// Existing ids are skipped, so this is safe to run during an upgrade.
  Future<void> _insertSampleAssignments(Database db) async {
    final now = DateTime.now();
    String dueIn(int days) => DateTime(
      now.year,
      now.month,
      now.day + days,
      23,
      59,
    ).toUtc().toIso8601String();

    for (final assignment in [
      {
        'id': 1,
        'module_code': 'ITMDA3-34',
        'title': 'Deliverable 4',
        'status': 'not_submitted',
        'due_date': dueIn(14),
      },
      {
        'id': 2,
        'module_code': 'ITMTA3-33',
        'title': 'Assignment 2: Integration',
        'status': 'not_submitted',
        'due_date': dueIn(7),
      },
      {
        'id': 3,
        'module_code': 'ITOPE3-33',
        'title': 'Practical 3: Scheduling',
        'status': 'not_submitted',
        'due_date': dueIn(21),
      },
    ]) {
      await db.insert(
        'assignments',
        assignment,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ---------------------------------------------------------------- Reading

  /// All grades stored on the phone: graded modules first, then "Pending".
  Future<List<Grade>> getGrades() async {
    final db = await database;
    final rows = await db.query(
      'grades',
      orderBy: 'mark IS NULL, module_code, id',
    );
    return rows.map((row) => Grade.fromJson(row)).toList();
  }

  /// Course materials stored on the phone, grouped by module (US04).
  Future<List<CourseMaterial>> getCourseMaterials() async {
    final db = await database;
    final rows = await db.query('course_materials', orderBy: 'module_code, id');
    return rows.map((row) => CourseMaterial.fromJson(row)).toList();
  }

  /// The student's weekly timetable (US01).
  Future<List<TimetableEntry>> getTimetable() async {
    final db = await database;
    final rows = await db.query('timetable', orderBy: 'id');
    return rows.map((row) => TimetableEntry.fromJson(row)).toList();
  }

  /// Announcements, newest first (US02).
  Future<List<Announcement>> getAnnouncements() async {
    final db = await database;
    final rows = await db.query('announcements', orderBy: 'posted_at DESC');
    return rows.map((row) => Announcement.fromJson(row)).toList();
  }

  /// The student's assignments and their status (US05).
  Future<List<Assignment>> getAssignments() async {
    final db = await database;
    final rows = await db.query('assignments', orderBy: 'due_date');
    return rows.map((row) => Assignment.fromJson(row)).toList();
  }

  /// One assignment (with its current status and submission id), or null.
  Future<Assignment?> getAssignment(int assignmentId) async {
    final db = await database;
    final rows = await db.query(
      'assignments',
      where: 'id = ?',
      whereArgs: [assignmentId],
      limit: 1,
    );
    return rows.isEmpty ? null : Assignment.fromJson(rows.first);
  }

  /// Grade queries the server already has, newest first.
  Future<List<GradeQuery>> getGradeQueries() async {
    final db = await database;
    final rows = await db.query('grade_queries', orderBy: 'query_id DESC');
    return rows.map((row) => GradeQuery.fromJson(row)).toList();
  }

  // ---------------------------------------------------------- Offline queue

  /// Saves an assignment submission made on the phone (US05, FR5, FR6).
  /// The assignment becomes "queued" and the change waits in pending_sync.
  /// Both happen in one transaction, so a change is never saved without
  /// its queue entry (D3 Reliability: no offline transaction is lost).
  /// [filePath] is uploaded by SyncService once the submission has synced.
  Future<void> queueAssignmentSubmission(
    Assignment assignment, {
    required String fileName,
    String? filePath,
    String? notes,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'assignments',
        {'status': 'queued'},
        where: 'id = ?',
        whereArgs: [assignment.id],
      );
      await txn.insert('pending_sync', {
        'entity_type': 'assignments',
        'entity_id': assignment.id,
        'operation_type': 'submit',
        'payload': jsonEncode({
          'title': assignment.title,
          'module_code': assignment.moduleCode,
          'status': 'submitted',
          'file_name': fileName,
          'file_path': filePath,
          'notes': notes,
          'client_updated_at': now,
        }),
        'created_at': now,
      });
    });
  }

  /// Saves a grade query flagged on the phone (wireframe Fig 5, FR5).
  /// [Grade.id] is the server's grade_id once the data has been synced.
  Future<void> queueGradeQuery(Grade grade, String reason) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert('pending_sync', {
      'entity_type': 'grade_queries',
      'entity_id': grade.id ?? 0,
      'operation_type': 'create',
      'payload': jsonEncode({
        'module_code': grade.moduleCode,
        'reason': reason,
        'client_updated_at': now,
      }),
      'created_at': now,
    });
  }

  /// Changes still waiting to reach the server, oldest first.
  Future<List<PendingChange>> getPendingChanges() async {
    final db = await database;
    final rows = await db.query(
      'pending_sync',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at',
    );
    return rows.map(PendingChange.fromRow).toList();
  }

  /// The most recently finished changes (synced or resolved as conflict).
  Future<List<PendingChange>> getRecentlySynced({int limit = 5}) async {
    final db = await database;
    final rows = await db.query(
      'pending_sync',
      where: "status IN ('synced', 'conflict')",
      orderBy: 'synced_at DESC',
      limit: limit,
    );
    return rows.map(PendingChange.fromRow).toList();
  }

  Future<void> markChangeSynced(int syncId) => _finishChange(syncId, 'synced');

  Future<void> markChangeConflict(int syncId) =>
      _finishChange(syncId, 'conflict');

  /// Removes an invalid change from the queue without sending it.
  Future<void> markChangeDiscarded(int syncId) =>
      _finishChange(syncId, 'discarded');

  Future<void> _finishChange(int syncId, String status) async {
    final db = await database;
    await db.update(
      'pending_sync',
      {'status': status, 'synced_at': DateTime.now().toUtc().toIso8601String()},
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
  }

  /// Counts a failed push; the change stays queued and is retried (D3
  /// Reliability: automatic retry after a communication failure).
  Future<void> recordFailedAttempt(int syncId) async {
    final db = await database;
    await db.rawUpdate(
      "UPDATE pending_sync SET attempts = attempts + 1, status = 'failed' WHERE sync_id = ?",
      [syncId],
    );
  }

  Future<void> setAssignmentStatus(int assignmentId, String status) async {
    final db = await database;
    await db.update(
      'assignments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }

  /// Replaces the cached tables with the server's data from
  /// GET /sync/pull (FR10). Assignments still queued on the phone keep
  /// their "queued" status, so pulling never hides an unsent submission.
  /// Known module names are kept if the server sends none.
  Future<void> saveServerSnapshot(Map<String, dynamic> data) async {
    final db = await database;
    final queuedIds = {
      for (final change in await getPendingChanges())
        if (change.entityType == 'assignments') change.entityId,
    };
    final moduleNames = {
      for (final row in await db.query(
        'grades',
        columns: ['module_code', 'module_name'],
      ))
        row['module_code']: row['module_name'],
    };
    await db.transaction((txn) async {
      for (final table in [
        'assignments',
        'grades',
        'timetable',
        'announcements',
        'grade_queries',
      ]) {
        final rows = data[table];
        if (rows is! List) continue;
        await txn.delete(table);
        for (final row in rows) {
          final values = Map<String, Object?>.from(row as Map);
          if (table == 'assignments' && queuedIds.contains(values['id'])) {
            values['status'] = 'queued';
          }
          if (table == 'grades') {
            values['module_name'] ??= moduleNames[values['module_code']];
          }
          await txn.insert(table, values);
        }
      }
    });
  }

  // ------------------------------------------------------------- App values

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert('app_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// When the app last synced successfully with the server, or null.
  Future<DateTime?> getLastSyncedAt() async {
    final value = await getMeta('last_synced_at');
    return value == null ? null : DateTime.parse(value);
  }
}
