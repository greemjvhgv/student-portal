/// Short "how long ago" text for queue and sync times, e.g. "12 min ago".
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
  }
  return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'June',
  'July',
  'Aug',
  'Sept',
  'Oct',
  'Nov',
  'Dec',
];

/// Due date in the wireframe's style, e.g. "4 Sept, 23:59".
String formatDue(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}, ${clockTime(local)}';
}

/// Time of day on the phone's clock, e.g. "14:01" (wireframe Fig 8).
String clockTime(DateTime time) {
  final local = time.toLocal();
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}
