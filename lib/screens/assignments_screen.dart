import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/portal_app_bar.dart';

/// Submit Assignment (D3 Figure 7): offline banner, assignment header,
/// "Tap to attach file" box, optional notes, submit button and the
/// "Pending in local queue" list (US05).
///
/// Placeholder until LocalDbService and SyncService exist: the phone is
/// treated as offline and queued submissions are only kept in memory.
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  static const _navy = PortalAppBar.navy;
  static const _fieldFill = Color(0xFFF4F7FA);
  static const _fieldBorder = Color(0xFFB0C4DE);
  static const _queueFill = Color(0xFFF4F9FC);
  static const _queueBorder = Color(0xFF81D4FA);
  static const _queueText = Color(0xFF1E88E5);
  static const _bannerFill = Color(0xFFFFF8D6);
  static const _bannerText = Color(0xFFD32F2F);

  // TODO: replace with the real connection state (connectivity_plus).
  final bool _isOnline = false;

  final _notesController = TextEditingController();
  final List<String> _pendingQueue = ['D2_LitReview.pdf'];
  String? _attachedFileName;
  String? _attachmentError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

  void _submit() {
    if (_attachedFileName == null) {
      setState(() => _attachmentError = 'Please attach a file before submitting');
      return;
    }
    setState(() {
      _pendingQueue.add(_attachedFileName!);
      _attachedFileName = null;
      _notesController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? 'Assignment submitted'
              : 'Saved – it will sync automatically when you are back online',
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Submit Assignment'),
      body: SafeArea(
        child: ListView(
          children: [
            if (!_isOnline)
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
                  const Text(
                    'Project: Deliverable 3: Submission',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const Divider(),
                  Text(
                    'ITMDA3-34 • Due 4 Sept, 23:59',
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
                        onPressed: _submit,
                        child: Text(
                          _isOnline ? 'Submit' : 'Submit (will queue offline)',
                        ),
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
                  for (final fileName in _pendingQueue)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _queueFill,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _queueBorder, width: 2),
                      ),
                      child: Text(
                        '$fileName - Queued, not yet synced',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _queueText, letterSpacing: 0.4),
                      ),
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