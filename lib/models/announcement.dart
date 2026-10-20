class Announcement {
  final String title;
  final String body;
  final DateTime postedAt;

  Announcement({
    required this.title,
    required this.body,
    required this.postedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    title: json['title'],
    body: json['body'],
    postedAt: DateTime.parse(json['posted_at']),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'posted_at': postedAt.toIso8601String(),
  };
}
