import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Thrown when the backend can't be reached or answers with an error.
/// [message] is safe to show to the student.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Calls the FastAPI backend (docs/API_CONTRACT.md): the sync endpoints,
/// plus the submissions and grade-query CRUD endpoints used while online.
/// Every request carries the student's login token, because the backend
/// only answers logged-in students, and only about their own data.
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

  /// POST /sync/push: sends offline changes, returns {"status", "conflicts"}.
  Future<Map<String, dynamic>> pushChanges(
    List<Map<String, dynamic>> changes,
  ) async =>
      Map<String, dynamic>.from(await _post('/sync/push', changes) as Map);

  /// GET /sync/pull/{student_id}: the student's latest data from the server.
  Future<Map<String, dynamic>> pullChanges(int studentId) async =>
      Map<String, dynamic>.from(await _get('/sync/pull/$studentId') as Map);

  // ------------------------------------------- Submissions CRUD (Leo's API)

  /// PUT /assignments/submissions/{id}: uploads (or replaces) the file of
  /// the student's own submission.
  Future<void> uploadSubmissionFile(int submissionId, String filePath) async {
    final headers = await AuthService.authHeaders()
      ..remove('Content-Type');
    final request =
        http.MultipartRequest(
            'PUT',
            Uri.parse('$baseUrl/assignments/submissions/$submissionId'),
          )
          ..headers.addAll(headers)
          ..files.add(await http.MultipartFile.fromPath('file', filePath));
    await _send(
      () async => http.Response.fromStream(await _client.send(request)),
    );
  }

  /// DELETE /assignments/submissions/{id}: withdraws the submission. The
  /// assignment stays, as "not_submitted", so it can be submitted again.
  Future<void> withdrawSubmission(int submissionId) async {
    final headers = await AuthService.authHeaders();
    await _send(
      () => _client.delete(
        Uri.parse('$baseUrl/assignments/submissions/$submissionId'),
        headers: headers,
      ),
    );
  }

  // ----------------------------------------- Grade-query CRUD (Leo's API)

  /// PUT /grade-queries/{id}: edits the reason (only while pending).
  Future<void> updateGradeQuery(int queryId, String reason) async {
    final headers = await AuthService.authHeaders();
    await _send(
      () => _client.put(
        Uri.parse('$baseUrl/grade-queries/$queryId'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
  }

  /// DELETE /grade-queries/{id}: withdraws the query (only while pending).
  Future<void> withdrawGradeQuery(int queryId) async {
    final headers = await AuthService.authHeaders();
    await _send(
      () => _client.delete(
        Uri.parse('$baseUrl/grade-queries/$queryId'),
        headers: headers,
      ),
    );
  }

  Future<dynamic> _get(String path) async {
    final headers = await AuthService.authHeaders();
    return _send(
      () => _client.get(Uri.parse('$baseUrl$path'), headers: headers),
    );
  }

  Future<dynamic> _post(String path, Object body) async {
    final headers = await AuthService.authHeaders();
    return _send(
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  /// Sends a request, decodes the JSON reply, and turns every failure
  /// (no connection, timeout, error status) into an [ApiException].
  /// A 401 means the login expired: the saved login is cleared, so the
  /// app opens on the Login screen next time.
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return body;
      if (response.statusCode == 401) {
        await AuthService.handleUnauthorized();
        throw ApiException(
          'Your login has expired – please log out and log in again.',
          statusCode: 401,
        );
      }
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
