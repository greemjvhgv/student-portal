import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../services/local_db_service.dart';
import '../widgets/portal_app_bar.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  static const _navy = PortalAppBar.navy;
  static const _cardFill = Color(0xFFF4F7FA);
  static const _cardBorder = Color(0xFFB0C4DE);
  static const _markBlue = Color(0xFF4FC3F7);
  static const _flagRed = Color(0xFFD32F2F);
  static const _syncedGreen = Color(0xFF4CD964);

  final Future<List<Grade>> _gradesFuture = LocalDbService.instance.getGrades();

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

  Widget _gradeCard(Grade grade) {
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
                  grade.moduleCode,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  grade.moduleName ?? '',
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
                  FutureBuilder<List<Grade>>(
                    future: _gradesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text('Could not load grades from this device.');
                      }
                      final grades = snapshot.data!;
                      if (grades.isEmpty) {
                        return const Text('No grades yet.');
                      }
                      return Column(
                        children: [for (final grade in grades) _gradeCard(grade)],
                      );
                    },
                  ),
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