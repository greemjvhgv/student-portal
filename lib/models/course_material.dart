class CourseMaterial {
  final String moduleCode;
  final String title;
  final String? fileUrl;
  final String? localPath;

  const CourseMaterial({
    required this.moduleCode,
    required this.title,
    this.fileUrl,
    this.localPath,
  });

  bool get isCached => localPath != null;

  factory CourseMaterial.fromJson(Map<String, dynamic> json) => CourseMaterial(
        moduleCode: json['module_code'] as String? ?? '',
        title: json['title'] as String,
        fileUrl: json['file_url'] as String?,
        localPath: json['local_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'module_code': moduleCode,
        'title': title,
        'file_url': fileUrl,
        'local_path': localPath,
      };
}