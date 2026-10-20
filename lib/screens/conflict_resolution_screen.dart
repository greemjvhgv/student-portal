import 'package:flutter/material.dart';

import '../widgets/portal_app_bar.dart';

/// Owner: Annuschka. The D3 "Conflict Resolved" pop-up (Figure 8).
///
/// Shown after a sync when the server rejected an offline change because
/// its own version was newer (server wins, FR11–FR13, US06).
Future<void> showConflictResolvedDialog(
  BuildContext context, {
  required String recordName,
  String? serverUpdateTime,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => ConflictResolvedDialog(
      recordName: recordName,
      serverUpdateTime: serverUpdateTime,
    ),
  );
}

/// [recordName] is the record that changed, [serverUpdateTime] when the
/// server's newer version was saved.
class ConflictResolvedDialog extends StatelessWidget {
  const ConflictResolvedDialog({
    super.key,
    required this.recordName,
    this.serverUpdateTime,
  });

  final String recordName;
  final String? serverUpdateTime;

  static const _navy = PortalAppBar.navy;
  static const _bodyStyle = TextStyle(fontSize: 16, color: _navy);

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final time = serverUpdateTime == null ? '' : ' ($serverUpdateTime)';
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
              'Your offline change to $recordName could not be applied as submitted.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'The official server version$time was more recent and took '
              'priority, to protect academic record integrity.',
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
                      navigator.pushNamed('/assignments');
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
