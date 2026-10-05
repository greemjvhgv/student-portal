/// Mirrors GET /grades/{student_id} — see docs/API_CONTRACT.md.
class Grade {
  final String moduleCode;
  final double mark;
  final DateTime updatedAt;

  Grade({required this.moduleCode, required this.mark, required this.updatedAt});

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        moduleCode: json['module_code'],
        mark: (json['mark'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'module_code': moduleCode,
        'mark': mark,
        'updated_at': updatedAt.toIso8601String(),
      };
}
