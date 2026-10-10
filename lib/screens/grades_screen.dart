import 'package:flutter/material.dart';
import '../widgets/portal_app_bar.dart';

typedef _GradeRow = ({String code, String name, double? mark});

/// My Grades (D3 Figure 5): one card per module with its mark or
/// "Pending", a "Flag a grade query" button and a "Last synced" footer.
/// Uses placeholder data until LocalDbService is built.
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  static const _navy = PortalAppBar.navy;
  static const _cardFill = Color(0xFFF4F7FA);
  static const _cardBorder = Color(0xFFB0C4DE);
  static const _markBlue = Color(0xFF4FC3F7);
  static const _flagRed = Color(0xFFD32F2F);
  static const _syncedGreen = Color(0xFF4CD964);

  static const List<_GradeRow> _grades = [
    (code: 'ITMDA3-34', name: 'Project - Mobile & Web Services', mark: 84.0),
    (code: 'ITMTA3-33', name: 'Calculus Mathematics', mark: 72.0),
    (code: 'ITOPE3-33', name: 'Operating Systems', mark: null),
  ];

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

  Widget _gradeCard(_GradeRow grade) {
    final isPending = grade.mark == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.code,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  grade.name,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPending ? 'Pending' : '${grade.mark!.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: isPending ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: isPending ? _navy : _markBlue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'My Grades'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final grade in _grades) _gradeCard(grade),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _flagRed,
                          side: const BorderSide(color: _flagRed, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () => _showGradeQueryDialog(context),
                        child: const Text('Flag a grade query'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: Column(
                children: [
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 14, color: _syncedGreen),
                      SizedBox(width: 6),
                      Text(
                        'Last synced 2 minutes ago',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}