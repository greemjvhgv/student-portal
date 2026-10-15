import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/pending_change.dart';
import '../services/connectivity_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../utils/time_format.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/portal_app_bar.dart';

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

  final _notesController = TextEditingController();
  String? _attachedFileName;
  String? _attachmentError;
  bool _isSaving = false;
  late Future<List<PendingChange>> _queueFuture = _loadQueue();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<List<PendingChange>> _loadQueue() async {
    final pending = await LocalDbService.instance.getPendingChanges();
    return pending
        .where((c) => c.entityType == 'assignments' && c.entityId == widget.assignment.id)
        .toList();
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (file == null || !mounted) return;
    setState(() {
      _attachedFileName = file.name;
      _attachmentError = null;
    });
  }

  Future<void> _submit() async {
    if (_attachedFileName == null) {
      setState(() => _attachmentError = 'Please attach a file before submitting');
      return;
    }
    setState(() => _isSaving = true);
    final notes = _notesController.text.trim();
    await LocalDbService.instance.queueAssignmentSubmission(
      widget.assignment,
      fileName: _attachedFileName!,
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
      _attachedFileName = null;
      _notesController.clear();
      _queueFuture = _loadQueue();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: _bannerText),
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
                          : '${assignment.moduleCode} \u2022 Due ${formatDue(assignment.dueDate!)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
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
                            _attachedFileName ?? 'Tap to attach file',
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.6,
                              color: _attachedFileName == null ? Colors.grey : _navy,
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
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isOnline ? 'Submit' : 'Submit (will queue offline)'),
                        ),
                      ),
                    ),
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
                                  border: Border.all(color: _queueBorder, width: 2),
                                ),
                                child: Text(
                                  '${change.payload['file_name']} - Queued ${timeAgo(change.createdAt)}, not yet synced',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _queueText, letterSpacing: 0.4),
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