class TimetableEntry {
  final String moduleCode;
  final String day;
  final String time;
  final String type;
  final String? venue;

  const TimetableEntry({
    required this.moduleCode,
    required this.day,
    required this.time,
    required this.type,
    this.venue,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
    moduleCode: json['module_code'] as String,
    day: json['day'] as String,
    time: json['time'] as String,
    type: json['type'] as String? ?? 'Class',
    venue: json['venue'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'module_code': moduleCode,
    'day': day,
    'time': time,
    'type': type,
    'venue': venue,
  };
}
