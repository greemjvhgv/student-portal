/// Mirrors backend/app/models/student.py (first_name/last_name per Adnan's
/// D3 ERD, not a combined full_name).
class Student {
  final int id;
  final String studentNumber;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';

  Student({
    required this.id,
    required this.studentNumber,
    required this.firstName,
    required this.lastName,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['student_id'] ?? json['id'],
        studentNumber: json['student_number'],
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'student_id': id,
        'student_number': studentNumber,
        'first_name': firstName,
        'last_name': lastName,
      };
}
