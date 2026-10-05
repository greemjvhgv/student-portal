/// Mirrors GET /timetable/{student_id} — see docs/API_CONTRACT.md.
/// Backs US01 / the Dashboard wireframe's "Today's Timetable" card
/// (Charleen's screen).
class TimetableEntry {
  final String moduleCode;
  final String day;
  final String time;
  final String type;

  TimetableEntry({
    required this.moduleCode,
    required this.day,
    required this.time,
    required this.type,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        moduleCode: json['module_code'],
        day: json['day'],
        time: json['time'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'module_code': moduleCode,
        'day': day,
        'time': time,
        'type': type,
      };
}
