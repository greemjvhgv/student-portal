/// One timetable slot, as returned by GET /sync/pull (docs/API_CONTRACT.md)
/// and stored in the phone's local `timetable` table.
/// Backs US01 / the Dashboard wireframe's "Today's Timetable" card
/// (Charleen's screens). [venue] is the room, e.g. "Lab C303".
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
