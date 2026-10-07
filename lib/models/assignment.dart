/// Mirrors GET /assignments/{student_id} — see docs/API_CONTRACT.md.
/// `id` is the submission id (Adnan's ERD splits per-student status into
/// Submission, separate from the course-level Assignment).
/// Statuses (US05): not_submitted / queued / submitted.
class Assignment {
  final int id;
  final String moduleCode;
  final String title;
  final String status;
  final DateTime? dueDate;

  Assignment({
    required this.id,
    required this.moduleCode,
    required this.title,
    required this.status,
    this.dueDate,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'],
        moduleCode: json['module_code'],
        title: json['title'],
        status: json['status'],
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_code': moduleCode,
        'title': title,
        'status': status,
        'due_date': dueDate?.toIso8601String(),
      };
}
