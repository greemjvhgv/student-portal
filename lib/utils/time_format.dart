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
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June',
  'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

String formatDue(DateTime date) {
  final local = date.toLocal();
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]}, $hours:$minutes';
}