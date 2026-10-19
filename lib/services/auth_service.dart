import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Thrown by [AuthService.login]; [message] is safe to show to the student.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Owner: Ruan — authentication. Calls POST /auth/login (see
/// docs/API_CONTRACT.md) and keeps the token in secure storage so the app
/// can open straight to the dashboard, including offline.
///
/// Offline note: a stored token is NOT checked for expiry on the device.
/// Only an actual 401 from the server (see [handleUnauthorized]) logs the
/// student out, so offline use of cached data keeps working.
class AuthService {
  static const _tokenKey = 'auth_token';
  static const _studentIdKey = 'student_id';
  static const _fullNameKey = 'full_name';

  static const _storage = FlutterSecureStorage();

  /// Logs in and persists the session. Throws [AuthException] with a
  /// student-friendly message on failure.
  static Future<void> login(String studentNumber, String password) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_number': studentNumber.trim().toUpperCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw const AuthException(
          'No connection. You need to be online for your first login.');
    } on TimeoutException {
      throw const AuthException('The server took too long to respond.');
    } on http.ClientException {
      throw const AuthException(
          'No connection. You need to be online for your first login.');
    }

    if (response.statusCode == 401) {
      throw const AuthException('Wrong student number or password.');
    }
    if (response.statusCode != 200) {
      throw AuthException('Login failed (error ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['token'] as String);
    await _storage.write(
        key: _studentIdKey, value: (data['student_id'] as int).toString());
    await _storage.write(key: _fullNameKey, value: data['full_name'] as String);
  }

  static Future<bool> isLoggedIn() async =>
      (await _storage.read(key: _tokenKey)) != null;

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<int?> getStudentId() async {
    final value = await _storage.read(key: _studentIdKey);
    return value == null ? null : int.tryParse(value);
  }

  static Future<String?> getFullName() => _storage.read(key: _fullNameKey);

  /// Header for authenticated requests, e.g. in SyncService:
  /// `headers: await AuthService.authHeaders()`.
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> logout() => _storage.deleteAll();

  /// Call when any API response is 401 (token expired/invalid): clears the
  /// session so the caller can send the student back to /login.
  static Future<void> handleUnauthorized() => logout();
}
