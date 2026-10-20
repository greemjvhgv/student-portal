/// One assignment and this student's submission status, as returned by
/// GET /assignments/{student_id} and GET /sync/pull (docs/API_CONTRACT.md)
/// and stored in the phone's local `assignments` table.
/// [status] (US05): not_submitted / queued (waiting to sync) / submitted.
/// [submissionId] is the student's own Submission on the server, needed to
/// replace the file or withdraw it; null until the data has been synced.
class Assignment {
  final int id;
  final String moduleCode;
  final String title;
  final String status;
  final DateTime? dueDate;
  final int? submissionId;

  const Assignment({
    required this.id,
    required this.moduleCode,
    required this.title,
    required this.status,
    this.dueDate,
    this.submissionId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id'] as int,
    moduleCode: json['module_code'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    dueDate: json['due_date'] != null
        ? DateTime.parse(json['due_date'] as String)
        : null,
    submissionId: json['submission_id'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'module_code': moduleCode,
    'title': title,
    'status': status,
    'due_date': dueDate?.toIso8601String(),
    'submission_id': submissionId,
  };
}
