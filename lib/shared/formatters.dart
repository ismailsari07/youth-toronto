import '../core/event_schedule.dart';
import '../core/models.dart';
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

/// "12 September" — the marriage service's "Submitted" date.
String dayMonth(DateTime dt) => '${dt.day} ${_monthsLong[dt.month]}';

/// "1.8 MB", "240 KB" — file sizes on the marriage service's file card.
/// Decimal units, as phones show them in their file pickers.
String fileSize(int bytes) {
  if (bytes >= 1000 * 1000) {
    return '${(bytes / (1000 * 1000)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1000).ceil()} KB';
}

/// "March 2024" — used for "Member since".
String monthYear(DateTime dt) => '${_monthsLong[dt.month]} ${dt.year}';

// ── Recurring and prayer-linked events (spec §7.3) ──────────────────────────
// Every DateTime passed here is a mosque-clock time (event_schedule.dart).

/// What the recurring badge means, for screen readers: "Repeats weekly".
String recurrenceSpoken(EventRecurrence r) => switch (r) {
      EventRecurrence.weekly => 'Repeats weekly',
      EventRecurrence.biweekly => 'Repeats every 2 weeks',
      EventRecurrence.monthly => 'Repeats monthly',
      EventRecurrence.none => '',
    };

/// The cadence at the start of the when line: "Every Wednesday",
/// "Every 2 weeks", "Monthly".
String recurrenceWhen(EventRecurrence r, DateTime session) => switch (r) {
      EventRecurrence.weekly => 'Every ${_weekdaysLong[session.weekday]}',
      EventRecurrence.biweekly => 'Every 2 weeks',
      EventRecurrence.monthly => 'Monthly',
      EventRecurrence.none => '',
    };

/// Detail eyebrow: "WEEKLY PROGRAMME"; one-off events keep "EVENT".
String eventEyebrow(EventRecurrence r) => switch (r) {
      EventRecurrence.weekly => 'WEEKLY PROGRAMME',
      EventRecurrence.biweekly => 'BIWEEKLY PROGRAMME',
      EventRecurrence.monthly => 'MONTHLY PROGRAMME',
      EventRecurrence.none => 'EVENT',
    };

/// Detail repeat row: ("Every Wednesday", "Weekly programme").
(String, String) recurrenceRow(EventRecurrence r, DateTime session) =>
    switch (r) {
      EventRecurrence.weekly => (
          'Every ${_weekdaysLong[session.weekday]}',
          'Weekly programme',
        ),
      EventRecurrence.biweekly => (
          'Every other ${_weekdaysLong[session.weekday]}',
          'Programme every 2 weeks',
        ),
      EventRecurrence.monthly => (
          'Every month on the ${_ordinal(session.day)}',
          'Monthly programme',
        ),
      EventRecurrence.none => ('', ''),
    };

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// "Wed 30 Sep".
String shortDate(DateTime dt) =>
    '${_weekdays[dt.weekday]} ${dt.day} ${_months[dt.month]}';

/// "next: Wed 30 Sep".
String nextShort(DateTime dt) => 'next: ${shortDate(dt)}';

/// "30 September".
String dayMonthLong(DateTime dt) => '${dt.day} ${_monthsLong[dt.month]}';

/// "Maghrib" for `maghrib`.
String prayerDisplay(String key) => prayerName(key);

/// The single plain-text line for a session, used where there is no room
/// for icons (the Community header, share text):
/// "Every Wednesday · 7:30 PM", "Fri 2 Oct · after Maghrib",
/// "Every Friday · after Maghrib", "Sat 26 Sep · 6:30 PM".
String sessionLine(UpcomingEvent u) {
  final e = u.event;
  final lead = e.repeats.isRecurring
      ? recurrenceWhen(e.repeats, u.startsAt)
      : shortDate(u.startsAt);
  final prayer = e.startsAfterPrayer;
  final when = prayer == null
      ? eventTime(u.startsAt)
      : 'after ${prayerDisplay(prayer)}';
  return '$lead · $when';
}

/// The next session with its date: "Wed 30 Sep · 7:30 PM", or
/// "Fri 2 Oct · after Maghrib" when prayer-linked.
String nextSessionLine(UpcomingEvent u) {
  final prayer = u.event.startsAfterPrayer;
  return prayer == null
      ? heroDateTime(u.startsAt)
      : '${shortDate(u.startsAt)} · after ${prayerDisplay(prayer)}';
}

/// Share text for an event: title, when, place, registration link.
String eventShareText(UpcomingEvent u) {
  final e = u.event;
  final location = e.location?.trim();
  return [
    e.title,
    e.repeats.isRecurring
        ? '${sessionLine(u)} (${nextShort(u.startsAt)})'
        : nextSessionLine(u),
    if (location != null && location.isNotEmpty) location,
    if (e.registrationUri != null) 'Register: ${e.registrationUri}',
  ].join('\n');
}
