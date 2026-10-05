import 'package:flutter/material.dart';

/// Matches the Grades wireframe (D3 Figure 5): list of module cards
/// (module code, name, mark/status), a "Flag a grade query" button, a
/// "Last synced" footer.
///
/// Owner: Annuschka (you). Follow login_screen.dart's shape. TODO:
///   - read from LocalDbService first (offline viewing — US03)
///   - show "Pending" for ungraded modules
///   - "Flag a grade query" queues an offline-capable request (see US03's
///     conflict-resolution note: a flagged query can be overridden by a
///     more recent lecturer update — surfaced via ConflictResolutionScreen)
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Grades')),
      body: const Center(
        child: Text('TODO: list grades, cached locally for offline viewing'),
      ),
    );
  }
}
