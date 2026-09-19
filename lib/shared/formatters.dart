import '../core/mosque_time.dart';

// Date/time formatting shared by Home, Events and News.

const _months3 = <String>[
  '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

const _months = <String>[
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _weekdays = <String>['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

/// Hero/subtitle date, kept short so it stays on one line:
/// "Sat 26 Sep · 6:30 PM".
String heroDateTime(DateTime dt) =>
    '${_weekdays[dt.weekday]} ${dt.day} ${_months[dt.month]} · ${eventTime(dt)}';

/// Screen title date: "Wednesday, 23 September".
String todayTitle() {
  final now = DateTime.now();
  return '${_weekdaysLong[now.weekday]}, ${now.day} ${_monthsLong[now.month]}';
}

/// prayer_cache stores `gregorianDate` as dd.MM.yyyy.
String? gregorianTitle(String? raw) {
  if (raw == null) return null;
  final parts = raw.split('.');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || m < 1 || m > 12) return null;
  final weekday = DateTime(y, m, d).weekday;
  return '${_weekdaysLong[weekday]}, $d ${_monthsLong[m]}';
}

const _weekdaysLong = <String>[
  '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  'Sunday',
];

const _monthsLong = <String>[
  '', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

/// prayer_cache mixes 24-hour morning times ("05:24") with 12-hour afternoon
/// ones ("1:16"); mosque_time resolves which is which by prayer name. This
/// renders them all as "5:24 AM".
String prayerClock12(String prayerName, String stored) {
  final clock = prayerClock(prayerName, stored);
  if (clock == null) return stored;
  final h = clock.hour % 12 == 0 ? 12 : clock.hour % 12;
  final suffix = clock.hour >= 12 ? 'PM' : 'AM';
  return '$h:${clock.minute.toString().padLeft(2, '0')} $suffix';
}

/// prayer_cache stores `hijriDate` as d.M.yyyy — "11.2.1448" → "11 Safar 1448".
String? hijriTitle(String? raw) {
  if (raw == null) return null;
  final parts = raw.split('.');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || m < 1 || m > 12) return null;
  return '$d ${_hijriMonths[m]} $y';
}

const _hijriMonths = <String>[
  '', 'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
  'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban", 'Ramadan',
  'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
];

/// "Saturday 26 September" — used as a detail-screen row title.
String longDate(DateTime dt) =>
    '${_weekdaysLong[dt.weekday]} ${dt.day} ${_monthsLong[dt.month]}';
