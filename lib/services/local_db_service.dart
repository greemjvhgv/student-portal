import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/grade.dart';

class LocalDbService {
  LocalDbService._internal();
  static final LocalDbService instance = LocalDbService._internal();

  static const _dbName = 'student_portal.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in _createTables) {
      await db.execute(statement);
    }
    await _insertPlaceholderData(db);
  }

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
        'due_date TEXT)',
    'CREATE TABLE timetable ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'module_code TEXT NOT NULL, '
        'day TEXT NOT NULL, '
        'time TEXT NOT NULL, '
        'type TEXT)',
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
        'attempts INTEGER NOT NULL DEFAULT 0)',
  ];

  Future<void> _insertPlaceholderData(Database db) async {
    final now = DateTime.now().toUtc();
    final batch = db.batch();

    for (final grade in [
      {'module_code': 'ITMDA3-34', 'module_name': 'Project - Mobile & Web Services', 'mark': 84.0},
      {'module_code': 'ITMTA3-33', 'module_name': 'Calculus Mathematics', 'mark': 72.0},
      {'module_code': 'ITOPE3-33', 'module_name': 'Operating Systems', 'mark': null},
    ]) {
      batch.insert('grades', {...grade, 'updated_at': now.toIso8601String()});
    }

    batch.insert('assignments', {
      'id': 1,
      'module_code': 'ITMDA3-34',
      'title': 'Deliverable 4',
      'status': 'not_submitted',
      'due_date': now.add(const Duration(days: 14)).toIso8601String(),
    });

    for (final entry in [
      {'module_code': 'ITMDA3-34', 'day': 'Monday', 'time': '15:00', 'type': 'Consultation'},
      {'module_code': 'ITMDA3-34', 'day': 'Monday', 'time': '18:00', 'type': 'Lecture'},
      {'module_code': 'ITMTA3-33', 'day': 'Tuesday', 'time': '11:30', 'type': 'Practical'},
      {'module_code': 'ITOPE3-33', 'day': 'Thursday', 'time': '10:00', 'type': 'Tutorial'},
    ]) {
      batch.insert('timetable', entry);
    }

    for (final announcement in [
      {'title': 'Deliverable 3 due 4 Sept', 'body': 'Please upload all Deliverable 3 work before 4 Sept.', 'posted_at': '2026-09-01'},
      {'title': 'Portal maintenance', 'body': 'Saturday 10pm', 'posted_at': '2026-09-28'},
      {'title': 'New study guide uploaded', 'body': 'The updated ITMDA3-34 study guide is available.', 'posted_at': '2026-10-01'},
    ]) {
      batch.insert('announcements', announcement);
    }

    for (final material in [
      {'module_code': 'ITMDA3-34', 'title': 'Week 6 - Lecture Slides.pdf', 'local_path': 'cached'},
      {'module_code': 'ITMDA3-34', 'title': 'Study Guide - Databases.pdf', 'local_path': null},
      {'module_code': 'ITMTA3-33', 'title': 'Week 6 - Lecture Slides.pdf', 'local_path': 'cached'},
      {'module_code': 'ITMTA3-33', 'title': 'Week 6 - Course Slides.pdf', 'local_path': 'cached'},
      {'module_code': 'ITOPE3-33', 'title': 'Week 6 - Lecture Slides.pdf', 'local_path': 'cached'},
    ]) {
      batch.insert('course_materials', material);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Grade>> getGrades() async {
    final db = await database;
    final rows = await db.query('grades', orderBy: 'module_code');
    return rows.map((row) => Grade.fromJson(row)).toList();
  }
}