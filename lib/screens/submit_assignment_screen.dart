import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/pending_change.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/time_format.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/portal_app_bar.dart';

/// Owner: Annuschka. Matches the D3 "Submit Assignment" wireframe (Fig 7).
///
/// Submissions module (US05, FR5, FR6):
///  * Submit: always saved to the local queue first, so it works offline;
///    when online it syncs straight away and the file is uploaded.
///  * Replace file / Withdraw: for a submitted assignment, while online
///    (they change the server's copy directly, using Leo's CRUD endpoints).
///  * "Pending in local queue" lists what is still waiting to sync.
class SubmitAssignmentScreen extends StatefulWidget {
  const SubmitAssignmentScreen({super.key, required this.assignment});

  final Assignment assignment;

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  static const _navy = PortalAppBar.navy;
  static const _fieldFill = Color(0xFFF4F7FA);
  static const _fieldBorder = Color(0xFFB0C4DE);
  static const _queueFill = Color(0xFFF4F9FC);
  static const _queueBorder = Color(0xFF81D4FA);
  static const _queueText = Color(0xFF1E88E5);
  static const _bannerFill = Color(0xFFFFF8D6);
  static const _bannerText = Color(0xFFD32F2F);
  static const _doneFill = Color(0xFFE8F5E9);
  static const _doneText = Color(0xFF2E7D32);

  /// The file types the backend accepts (submission_files.py).
  static const _allowedExtensions = ['pdf', 'docx', 'txt'];

  final _notesController = TextEditingController();
  late Assignment _assignment = widget.assignment;
  PlatformFile? _attachedFile;
  String? _attachmentError;
  bool _isSaving = false;
  late Future<List<PendingChange>> _queueFuture = _loadQueue();

  @override
  void initState() {
    super.initState();
    SyncService.instance.changes.addListener(_reload);
  }

  @override
  void dispose() {
    SyncService.instance.changes.removeListener(_reload);
    _notesController.dispose();
    super.dispose();
  }

  /// Re-reads the assignment (status, submission id) and the queue, e.g.
  /// after a sync finished in the background.
  Future<void> _reload() async {
    final latest = await LocalDbService.instance.getAssignment(
      widget.assignment.id,
    );
    if (!mounted) return;
    setState(() {
      if (latest != null) _assignment = latest;
      _queueFuture = _loadQueue();
    });
  }

  Future<List<PendingChange>> _loadQueue() async {
    final pending = await LocalDbService.instance.getPendingChanges();
    return pending
        .where(
          (c) =>
              c.entityType == 'assignments' &&
              c.entityId == widget.assignment.id,
        )
        .toList();
  }

  Future<PlatformFile?> _chooseFile() => FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: _allowedExtensions,
  );

  Future<void> _pickFile() async {
    final file = await _chooseFile();
    if (file == null || !mounted) return;
    setState(() {
      _attachedFile = file;
      _attachmentError = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_attachedFile == null) {
      setState(
        () => _attachmentError = 'Please attach a file before submitting',
      );
      return;
    }
    setState(() => _isSaving = true);
    final notes = _notesController.text.trim();
    await LocalDbService.instance.queueAssignmentSubmission(
      _assignment,
      fileName: _attachedFile!.name,
      filePath: _attachedFile!.path,
      notes: notes.isEmpty ? null : notes,
    );
    SyncService.instance.notifyLocalChange();

    var message = 'Saved – it will sync automatically when you are back online';
    if (ConnectivityService.instance.isOnline.value) {
      final result = await SyncService.instance.syncNow();
      message = result.succeeded && result.pushed > 0
          ? 'Assignment submitted'
          : 'Saved on this device – it will be sent automatically (${result.error ?? result.summary})';
    }
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _attachedFile = null;
      _notesController.clear();
    });
    await _reload();
    _showMessage(message);
  }

  /// Uploads a new file for the submitted assignment (CRUD: update).
  Future<void> _replaceFile() async {
    final submissionId = _assignment.submissionId;
    final file = await _chooseFile();
    if (submissionId == null || file?.path == null) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.uploadSubmissionFile(submissionId, file!.path!);
      await SyncService.instance.syncNow();
      _showMessage('File replaced with ${file.name}');
    } on Exception catch (e) {
      _showMessage('File not replaced: $e');
    }
    if (mounted) setState(() => _isSaving = false);
    await _reload();
  }

  /// Withdraws the submission (CRUD: delete). The assignment stays in the
  /// list as "not submitted", so it can be submitted again.
  Future<void> _withdraw() async {
    final submissionId = _assignment.submissionId;
    if (submissionId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw submission?'),
        content: Text(
          'Your file for "${_assignment.title}" will be removed. '
          'You can submit again before the due date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.withdrawSubmission(submissionId);
      await SyncService.instance.syncNow();
      _showMessage('Submission withdrawn');
    } on Exception catch (e) {
      _showMessage('Not withdrawn: $e');
    }
    if (mounted) setState(() => _isSaving = false);
    await _reload();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: 2),
  );

  /// Shown instead of the form once the server has the submission.
  Widget _submittedCard(bool isOnline) {
    final canChange =
        isOnline && _assignment.submissionId != null && !_isSaving;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _doneFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: _doneText),
              SizedBox(width: 8),
              Text(
                'Submitted',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _doneText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canChange ? _replaceFile : null,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Replace file'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: canChange ? _withdraw : null,
                  icon: const Icon(Icons.undo),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
          if (!isOnline)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Replacing or withdrawing needs a connection.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _submitForm(bool isOnline) {
    final isQueued = _assignment.status == 'queued';
    return [
      const Text('Attachment', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 6),
      InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: _attachmentError == null ? _fieldBorder : Colors.red,
          ),
          child: Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _attachedFile?.name ?? 'Tap to attach file (PDF, DOCX or TXT)',
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 0.6,
                color: _attachedFile == null ? Colors.grey : _navy,
              ),
            ),
          ),
        ),
      ),
      if (_attachmentError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _attachmentError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      const SizedBox(height: 20),
      const Text('Notes (optional)', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 6),
      TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldFill,
          enabledBorder: _border(_fieldBorder),
          focusedBorder: _border(_navy),
        ),
      ),
      const SizedBox(height: 28),
      Center(
        child: SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _isSaving || isQueued ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isQueued
                        ? 'Already queued'
                        : isOnline
                        ? 'Submit'
                        : 'Submit (will queue offline)',
                  ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: const PortalAppBar(title: 'Submit Assignment'),
        body: SafeArea(
          child: ListView(
            children: [
              if (!isOnline)
                Container(
                  color: _bannerFill,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: _bannerText,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'No connection - will queue and sync automatically',
                          style: TextStyle(color: _bannerText),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const Divider(),
                    Text(
                      assignment.dueDate == null
                          ? assignment.moduleCode
                          : '${assignment.moduleCode} • Due ${formatDue(assignment.dueDate!)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (assignment.status == 'submitted')
                      _submittedCard(isOnline)
                    else
                      ..._submitForm(isOnline),
                    const SizedBox(height: 28),
                    const Divider(),
                    const Text(
                      'Pending in local queue:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<PendingChange>>(
                      future: _queueFuture,
                      builder: (context, snapshot) {
                        final queue = snapshot.data ?? const <PendingChange>[];
                        if (queue.isEmpty) {
                          return const Text(
                            'Nothing waiting for this assignment.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final change in queue)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _queueFill,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _queueBorder,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${change.payload['file_name']} - Queued ${timeAgo(change.createdAt)}, not yet synced',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _queueText,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
