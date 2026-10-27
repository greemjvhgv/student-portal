import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration _timeout = Duration(seconds: 10);
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> pushChanges(
    List<Map<String, dynamic>> changes,
  ) async =>
      Map<String, dynamic>.from(await _post('/sync/push', changes) as Map);

  Future<Map<String, dynamic>> pullChanges(int studentId) async =>
      Map<String, dynamic>.from(await _get('/sync/pull/$studentId') as Map);


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

  Future<void> withdrawSubmission(int submissionId) async {
    final headers = await AuthService.authHeaders();
    await _send(
      () => _client.delete(
        Uri.parse('$baseUrl/assignments/submissions/$submissionId'),
        headers: headers,
      ),
    );
  }

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
