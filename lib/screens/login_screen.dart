import 'package:flutter/material.dart';

/// Login screen (D3 Figure 3): navy "Student Portal" bar, Eduvos logo,
/// student number + password fields, a Log In button and a footer note
/// that the app works offline once logged in.
///
/// TODO (when Ruan's POST /auth/login exists): replace the placeholder in
/// [_handleLogin] with the real call, save the token, and show real errors
/// (wrong password, no connection) through [_errorText].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _navy = Color(0xFF0B2545);
  static const _fieldFill = Color(0xFFF4F7FA);
  static const _fieldBorder = Color(0xFFB0C4DE);
  static const _taglineBlue = Color(0xFF1E88E5);

  static final RegExp _studentNumberPattern =
      RegExp(r'^EDUV\d{7}$', caseSensitive: false);

  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // TODO: replace with a real call to POST /auth/login.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  InputDecoration _fieldDecoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: 2),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fieldFill,
      enabledBorder: border(_fieldBorder),
      focusedBorder: border(_navy),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Student Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TODO: swap for the real Eduvos crest image once it is in assets/.
                const Icon(Icons.school, size: 72, color: _navy),
                const Text(
                  'Eduvos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const Text(
                  'Your Education. Your Future.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _taglineBlue),
                ),
                const SizedBox(height: 32),
                _label('Student Number'),
                TextFormField(
                  controller: _studentNumberController,
                  decoration: _fieldDecoration('e.g. EDUV1234567'),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter your student number';
                    if (!_studentNumberPattern.hasMatch(text)) {
                      return 'Use the format EDUV1234567';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _label('Password'),
                TextFormField(
                  controller: _passwordController,
                  decoration: _fieldDecoration('••••••••••'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter your password' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 4),
                const Text(
                  'Works Offline once logged in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}