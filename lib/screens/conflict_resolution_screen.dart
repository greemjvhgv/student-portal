import 'package:flutter/material.dart';
import '../widgets/portal_app_bar.dart';

Future<void> showConflictResolvedDialog(
  BuildContext context, {
  required String moduleCode,
  required String lecturerUpdateTime,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => ConflictResolvedDialog(
      moduleCode: moduleCode,
      lecturerUpdateTime: lecturerUpdateTime,
    ),
  );
}

class ConflictResolvedDialog extends StatelessWidget {
  const ConflictResolvedDialog({
    super.key,
    required this.moduleCode,
    required this.lecturerUpdateTime,
  });

  final String moduleCode;
  final String lecturerUpdateTime;

  static const _navy = PortalAppBar.navy;
  static const _bodyStyle = TextStyle(fontSize: 16, color: _navy);

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Dialog(
      backgroundColor: const Color(0xFFF7F9FC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _navy, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Conflict Resolved',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const Divider(height: 28),
            Text(
              'Your offline grade query for $moduleCode could not be applied as submitted.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 16),
            Text(
              "The lecturer's official grade update ($lecturerUpdateTime) was more "
              'recent and took priority, to protect academic record integrity.',
              style: _bodyStyle,
            ),
            const Divider(height: 28),
            const Text(
              'Resolved automatically using timestamp-based conflict rules',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _navy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      navigator.pop();
                      navigator.pushNamed('/grades');
                    },
                    child: const Text(
                      'View Record',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: navigator.pop,
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}