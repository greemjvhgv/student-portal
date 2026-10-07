import 'package:flutter/material.dart';

/// Matches the Course Materials wireframe (D3 Figure 4): files grouped by
/// module, each marked "Cached" or not, a low-storage warning banner.
///
/// Owner: Annuschka (you). Follow login_screen.dart's shape. TODO:
///   - list from GET /course-materials/{module_code}, cache file bytes
///     locally (device storage, not just the SQLite metadata) so they open
///     with zero network latency per the wireframe's footer note
class CourseMaterialsScreen extends StatelessWidget {
  const CourseMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Materials')),
      body: const Center(
        child: Text('TODO: downloaded materials list, cached for offline use'),
      ),
    );
  }
}
