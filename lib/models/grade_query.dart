/// A grade query the student sent about one of their grades (wireframe
/// Fig 5 "Flag a grade query"), as returned by GET /sync/pull and stored in
/// the phone's local `grade_queries` table.
/// [status] is "pending" (can still be edited or withdrawn) or "resolved".
class GradeQuery {
  final int queryId;
  final int gradeId;
  final String moduleCode;
  final String reason;
  final String status;

  const GradeQuery({
    required this.queryId,
    required this.gradeId,
    required this.moduleCode,
    required this.reason,
    required this.status,
  });

  bool get isPending => status == 'pending';

  factory GradeQuery.fromJson(Map<String, dynamic> json) => GradeQuery(
    queryId: json['query_id'] as int,
    gradeId: json['grade_id'] as int,
    moduleCode: json['module_code'] as String? ?? '',
    reason: json['reason'] as String,
    status: json['status'] as String,
  );
}
