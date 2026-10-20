/// One grade, as returned by GET /sync/pull (docs/API_CONTRACT.md) and
/// stored in the phone's local `grades` table. [id] is the server's
/// grade_id (needed to flag a grade query); [mark] is null while the
/// module is still "Pending".
class Grade {
  final int? id;
  final String moduleCode;
  final String? moduleName;
  final double? mark;
  final DateTime? updatedAt;

  const Grade({
    this.id,
    required this.moduleCode,
    this.moduleName,
    this.mark,
    this.updatedAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: json['id'] as int?,
    moduleCode: json['module_code'] as String,
    moduleName: json['module_name'] as String?,
    mark: (json['mark'] as num?)?.toDouble(),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'module_code': moduleCode,
    'module_name': moduleName,
    'mark': mark,
    'updated_at': updatedAt?.toIso8601String(),
  };
}
