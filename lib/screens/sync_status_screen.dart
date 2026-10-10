import 'package:flutter/material.dart';
import '../widgets/portal_app_bar.dart';
import 'conflict_resolution_screen.dart';


/// Placeholder until SyncService exists. TEMPORARY: tap the status card
/// to switch Offline/Online so both states can be tested.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  static const _navy = PortalAppBar.navy;
  static const _queueFill = Color(0xFFF4F9FC);
  static const _queueBorder = Color(0xFF81D4FA);
  static const _blueText = Color(0xFF29B6F6);
  static const _syncedFill = Color(0xFFF4F7FA);
  static const _syncedBorder = Color(0xFFB0C4DE);

  // TODO: replace with the real connection state (connectivity_plus).
  bool _isOnline = false;

  static const List<({String title, String time})> _pending = [
    (title: 'Assignment: Deliverable 3', time: 'Queued 12 min ago'),
    (title: 'Grade query - ITOPE3-33', time: 'Queued 40 min ago'),
    (title: 'Profile update', time: 'Queued 1 hr ago'),
  ];
  static const List<({String title, String time})> _synced = [
    (title: 'Timetable refreshed', time: 'Synced 2 hrs ago'),
  ];

  void _syncNow() {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You're offline – sync will resume automatically when you're back online",
          ),
        ),
      );
      return;
    }
    showConflictResolvedDialog(
      context,
      moduleCode: 'ITOPE3-33',
      lecturerUpdateTime: '14:01',
    );
  }

  Widget _statusCard() {
    final fill = _isOnline ? const Color(0xFFEFFAF1) : const Color(0xFFFFF1F1);
    final border = _isOnline ? const Color(0xFF81C784) : const Color(0xFFFF8A8A);
    final dot = _isOnline ? const Color(0xFF4CD964) : const Color(0xFFD32F2F);
    final text = _isOnline ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    return GestureDetector(
      onTap: () => setState(() => _isOnline = !_isOnline),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 3),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 28, color: dot),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  Text(
                    _isOnline
                        ? 'Ready to sync'
                        : 'Sync will resume automatically',
                    style: TextStyle(fontSize: 16, color: text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(({String title, String time}) item, Color fill, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 17, color: _navy)),
          const SizedBox(height: 4),
          Text(item.time, style: const TextStyle(fontSize: 16, color: _blueText)),
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _navy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Sync Status'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusCard(),
            _heading('Pending items (${_pending.length})'),
            for (final item in _pending) _itemCard(item, _queueFill, _queueBorder),
            _heading('Recently synced'),
            for (final item in _synced) _itemCard(item, _syncedFill, _syncedBorder),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                height: 52,
                width: 240,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _syncNow,
                  child: const Text('Sync Now'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}