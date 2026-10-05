/// Mirrors GET /course-materials/{module_code} — see docs/API_CONTRACT.md.
/// Backs US04 / the Course Materials wireframe.
class CourseMaterial {
  final String title;
  final String fileUrl;

  CourseMaterial({required this.title, required this.fileUrl});

  factory CourseMaterial.fromJson(Map<String, dynamic> json) => CourseMaterial(
        title: json['title'],
        fileUrl: json['file_url'],
      );

  Map<String, dynamic> toJson() => {'title': title, 'file_url': fileUrl};
}
