import 'package:flutter/material.dart';

import '../widgets/offline_badge.dart';

/// My Grades (D3 Figure 5): one card per module with its mark or
/// "Pending", a "Flag a grade query" button and a "Last synced" footer.
/// Uses placeholder data until LocalDbService is built.
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  // Placeholder data from the wireframe. A null mark means "Pending".
  static const List<({String code, String name, double? mark})> _grades = [
    (code: 'ITMDA3-34', name: 'Project - Mobile & Web Services', mark: 78.0),
    (code: 'ITMTA3-33', name: 'Calculus Mathematics', mark: 64.0),
    (code: 'ITOPE3-33', name: 'Operating Systems', mark: null),
  ];

  /// Asks for the reason, validates it, then confirms the query was queued.
  Future<void> _showGradeQueryDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Flag a grade query'),
        content: Form(
          key: formKey,
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a reason'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (submitted != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grade query queued – it will sync when you are online'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OfflineBadge(isOnline: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final grade in _grades)
            Card(
              child: ListTile(
                title: Text(
                  grade.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(grade.name),
                trailing: Text(
                  grade.mark == null
                      ? 'Pending'
                      : '${grade.mark!.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showGradeQueryDialog(context),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Flag a grade query'),
          ),
          const SizedBox(height: 16),
          const Text('Last synced 2 minutes ago', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}