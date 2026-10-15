import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  /// Phone over USB with `adb reverse tcp:8000 tcp:8000`: 127.0.0.1.
  /// Override without code changes, e.g. for the emulator:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration _timeout = Duration(seconds: 10);
  final http.Client _client = http.Client();

  /// POST /auth/login (FR1).
  Future<Map<String, dynamic>> login(String studentNumber, String password) async =>
      Map<String, dynamic>.from(await _post('/auth/login', {
        'student_number': studentNumber,
        'password': password,
      }) as Map);

  /// GET /timetable/{student_id}
  Future<List<dynamic>> getTimetable(int studentId) async =>
      await _get('/timetable/$studentId') as List<dynamic>;

  /// GET /announcements
  Future<List<dynamic>> getAnnouncements() async =>
      await _get('/announcements') as List<dynamic>;

  /// GET /grades/{student_id}
  Future<List<dynamic>> getGrades(int studentId) async =>
      await _get('/grades/$studentId') as List<dynamic>;

  /// GET /assignments/{student_id}
  Future<List<dynamic>> getAssignments(int studentId) async =>
      await _get('/assignments/$studentId') as List<dynamic>;

  /// GET /course-materials/{module_code}
  Future<List<dynamic>> getCourseMaterials(String moduleCode) async =>
      await _get('/course-materials/${Uri.encodeComponent(moduleCode)}') as List<dynamic>;

  /// POST /sync/push: sends offline changes, returns {"status", "conflicts"}.
  Future<Map<String, dynamic>> pushChanges(List<Map<String, dynamic>> changes) async =>
      Map<String, dynamic>.from(await _post('/sync/push', changes) as Map);


  Future<Map<String, dynamic>> pullChanges(int studentId) async =>
      Map<String, dynamic>.from(await _get('/sync/pull/$studentId') as Map);

  Future<dynamic> _get(String path) =>
      _send(() => _client.get(Uri.parse('$baseUrl$path')));

  Future<dynamic> _post(String path, Object body) => _send(() => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return body;
      final detail = body is Map && body['detail'] != null
          ? body['detail'].toString()
          : 'Server error (${response.statusCode})';
      throw ApiException(detail, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException('Could not reach the server.');
    }
  }
}