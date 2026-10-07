import 'package:flutter/material.dart';

/// Shared online/offline indicator pill — every screen in the D3 wireframes
/// shows one (NFR Usability: "interface must clearly show online/offline
/// state"). Used by Dashboard, Grades, Sync Status, etc.
///
/// This is presentation-only right now: pass `isOnline` in from whatever
/// actually tracks connectivity (TODO in lib/services/sync_service.dart —
/// likely the `connectivity_plus` package once it's added to pubspec.yaml).
class OfflineBadge extends StatelessWidget {
  final bool isOnline;

  const OfflineBadge({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? Colors.green : Colors.red;
    final label = isOnline ? 'Online' : 'Offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
