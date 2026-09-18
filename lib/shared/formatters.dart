// Date/time formatting shared by Home, Events and News.

const _months3 = <String>[
  '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// Relative age, e.g. "3 hours ago", "2 weeks ago".
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 28) return '${(diff.inDays / 7).floor()} weeks ago';
  return '${(diff.inDays / 30).floor()} months ago';
}

/// 12-hour clock time, e.g. "7:30 PM".
String eventTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

/// Event card date, e.g. "MAY 8 · 7:30 PM".
String eventCardDate(DateTime dt) =>
    '${_months3[dt.month]} ${dt.day} · ${eventTime(dt)}';
