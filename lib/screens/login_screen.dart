import 'package:flutter/material.dart';

/// Matches the Login wireframe (D3 Figure 3): student number + password
/// fields, a Log In button, and a footer note that the app works offline
/// once logged in. This one's built out as a worked example — copy this
/// file's shape (StatefulWidget + a form + a loading state) for the other
/// screens.
///
/// TODO:
///   - wire `_handleLogin` to call POST /auth/login (see
///     docs/API_CONTRACT.md) via an ApiService you add to lib/services/
///   - on success, save the token + student_id (local_db_service.dart can
///     hold a tiny "current session" table for this) and navigate to
///     DashboardScreen
///   - show a real error state (wrong credentials, no connection — login
///     itself needs a first-time connection; offline-first starts *after*
///     login, per the wireframe's footer note)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _studentNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // TODO: replace with a real call to POST /auth/login.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TODO: swap for the real Eduvos crest asset once added to
                // the assets/ folder and declared in pubspec.yaml.
                const Icon(Icons.school, size: 64),
                const SizedBox(height: 8),
                const Text(
                  'Student Portal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _studentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Student Number',
                    hintText: 'e.g. EDUV1234567',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Works offline once logged in',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
