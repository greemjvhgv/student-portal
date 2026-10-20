import 'package:flutter/material.dart';

import '../models/grade.dart';
import '../models/grade_query.dart';
import '../models/pending_change.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/time_format.dart';
import '../widgets/portal_app_bar.dart';

/// Owner: Annuschka. Matches the D3 "My Grades" wireframe (Fig 5).
///
/// Shows the grades cached on the phone (US03, works offline) and the
/// grade-queries module (create / read / update / delete):
///  * "Flag a grade query" saves the query to the local queue, so it also
///    works offline, and SyncService sends it (FR5, FR6).
///  * "My grade queries" lists the queries the server has plus the ones
///    still queued. Pending ones can be edited or withdrawn while online.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

/// Everything the screen shows, read from the local database in one go.
class _GradesData {
  const _GradesData(this.grades, this.queries, this.queued, this.lastSynced);

  final List<Grade> grades;
  final List<GradeQuery> queries;
  final List<PendingChange> queued;
  final DateTime? lastSynced;
}

class _GradesScreenState extends State<GradesScreen> {
  static const _navy = PortalAppBar.navy;
  static const _cardFill = Color(0xFFF4F7FA);
  static const _cardBorder = Color(0xFFB0C4DE);
  static const _markBlue = Color(0xFF4FC3F7);
  static const _flagRed = Color(0xFFD32F2F);
  static const _syncedGreen = Color(0xFF4CD964);
  static const _queueText = Color(0xFF1E88E5);

  /// The backend rejects shorter reasons (schemas/grade_query.py).
  static const _minReasonLength = 10;

  late Future<_GradesData> _dataFuture = _load();

  @override
  void initState() {
    super.initState();
    SyncService.instance.changes.addListener(_reload);
  }

  @override
  void dispose() {
    SyncService.instance.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _dataFuture = _load());
  }

  Future<_GradesData> _load() async {
    final db = LocalDbService.instance;
    final pending = await db.getPendingChanges();
    return _GradesData(
      await db.getGrades(),
      await db.getGradeQueries(),
      pending.where((c) => c.entityType == 'grade_queries').toList(),
      await db.getLastSyncedAt(),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateReason(String? value) {
    final reason = value?.trim() ?? '';
    if (reason.isEmpty) return 'Please enter a reason';
    if (reason.length < _minReasonLength) {
      return 'Please use at least $_minReasonLength characters';
    }
    return null;
  }

  /// Create: pick one of your marked grades and give a reason.
  Future<void> _showGradeQueryDialog() async {
    final data = await _dataFuture;
    // Only marked grades the server has sent (they carry its grade_id).
    final grades = data.lastSynced == null
        ? const <Grade>[]
        : data.grades.where((g) => g.mark != null && g.id != null).toList();
    if (!mounted) return;
    if (grades.isEmpty) {
      _showMessage('Sync once while online to load the grades you can query.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    var selected = grades.first;
    var reason = '';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Flag a grade query'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Grade>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Grade'),
                items: [
                  for (final grade in grades)
                    DropdownMenuItem(
                      value: grade,
                      child: Text(
                        '${grade.moduleName ?? grade.moduleCode} (${grade.mark!.toStringAsFixed(0)}%)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (grade) {
                  if (grade != null) selected = grade;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 3,
                onChanged: (value) => reason = value,
                validator: _validateReason,
              ),
            ],
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
    if (submitted != true) return;

    await LocalDbService.instance.queueGradeQuery(selected, reason.trim());
    SyncService.instance.notifyLocalChange();
    if (ConnectivityService.instance.isOnline.value) {
      final result = await SyncService.instance.syncNow();
      _showMessage(
        result.succeeded
            ? 'Grade query for ${selected.moduleCode} sent'
            : 'Grade query saved – ${result.error}',
      );
    } else {
      _showMessage(
        'Grade query for ${selected.moduleCode} saved – it will sync when you are back online',
      );
    }
  }

  /// Update: change the reason of a pending query (online only).
  Future<void> _editQuery(GradeQuery query) async {
    final formKey = GlobalKey<FormState>();
    var reason = query.reason;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit query – ${query.moduleCode}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: query.reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
            onChanged: (value) => reason = value,
            validator: _validateReason,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ApiService.instance.updateGradeQuery(query.queryId, reason.trim());
      await SyncService.instance.syncNow();
      _showMessage('Grade query updated');
    } on ApiException catch (e) {
      _showMessage('Not updated: ${e.message}');
    }
  }

  /// Delete: withdraw a pending query (online only).
  Future<void> _withdrawQuery(GradeQuery query) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw grade query?'),
        content: Text('Your query about ${query.moduleCode} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw', style: TextStyle(color: _flagRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.withdrawGradeQuery(query.queryId);
      await SyncService.instance.syncNow();
      _showMessage('Grade query withdrawn');
    } on ApiException catch (e) {
      _showMessage('Not withdrawn: ${e.message}');
    }
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

  Widget _queryTile(GradeQuery query, bool isOnline) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(query.moduleCode, style: const TextStyle(color: _navy)),
        subtitle: Text('${query.reason}\nStatus: ${query.status}'),
        isThreeLine: true,
        trailing: query.isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isOnline ? 'Edit' : 'Editing needs a connection',
                    icon: const Icon(Icons.edit),
                    onPressed: isOnline ? () => _editQuery(query) : null,
                  ),
                  IconButton(
                    tooltip: isOnline
                        ? 'Withdraw'
                        : 'Withdrawing needs a connection',
                    icon: const Icon(Icons.delete_outline, color: _flagRed),
                    onPressed: isOnline ? () => _withdrawQuery(query) : null,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _queuedTile(PendingChange change) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${change.payload['module_code'] ?? ''}',
          style: const TextStyle(color: _navy),
        ),
        subtitle: Text(
          '${change.payload['reason']}\nQueued ${timeAgo(change.createdAt)}, not yet synced',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.schedule, color: _queueText),
      ),
    );
  }

  Widget _gradeQueriesSection(_GradesData data, bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'My grade queries',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 8),
        if (data.queries.isEmpty && data.queued.isEmpty)
          const Text(
            'No grade queries yet.',
            style: TextStyle(color: Colors.grey),
          ),
        for (final change in data.queued) _queuedTile(change),
        for (final query in data.queries) _queryTile(query, isOnline),
      ],
    );
  }

  Widget _lastSyncedFooter(DateTime? lastSynced) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.circle,
          size: 14,
          color: lastSynced == null ? Colors.grey : _syncedGreen,
        ),
        const SizedBox(width: 6),
        Text(
          lastSynced == null
              ? 'Not synced yet'
              : 'Last synced ${timeAgo(lastSynced)}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'My Grades'),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.isOnline,
          builder: (context, isOnline, _) => FutureBuilder<_GradesData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Could not load grades from this device.'),
                );
              }
              final data = snapshot.data;
              if (data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (data.grades.isEmpty) const Text('No grades yet.'),
                        for (final grade in data.grades) _gradeCard(grade),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _flagRed,
                                side: const BorderSide(
                                  color: _flagRed,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              onPressed: _showGradeQueryDialog,
                              child: const Text('Flag a grade query'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _gradeQueriesSection(data, isOnline),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        _lastSyncedFooter(data.lastSynced),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
