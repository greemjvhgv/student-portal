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
