import 'package:intl/intl.dart';

import '../core/event_schedule.dart';
import '../core/models.dart';
import '../core/mosque_info.dart';
import '../core/mosque_time.dart';
import '../l10n/l10n.dart';

// Date/time formatting shared by Home, Events and News. Every function takes
// the strings for the current language: words and date order come from the
// ARB files (the `datePattern*` keys), month and weekday names from intl.
//
// Clock times stay 12-hour ("7:30 PM") in every language: the mosque is in
// Canada, where that is how times are written.

String _format(AppLocalizations l, String pattern, DateTime dt) =>
    DateFormat(pattern, l.localeName).format(dt);

/// French writes weekdays and months in lower case; a date that opens a
/// title or a line still starts with a capital.
String _capitalised(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// Relative age, e.g. "3 hours ago", "il y a 2 semaines", "3 gün önce".
String timeAgo(AppLocalizations l, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.daysAgo(diff.inDays);
  if (diff.inDays < 28) return l.weeksAgo((diff.inDays / 7).floor());
  return l.monthsAgo((diff.inDays / 30).floor());
}

/// 12-hour clock time, e.g. "7:30 PM".
String eventTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

/// Event card date, e.g. "MAY 8 · 7:30 PM", "8 MAI · 7:30 PM".
String eventCardDate(AppLocalizations l, DateTime dt) =>
    '${upper(_format(l, l.datePatternCard, dt), l.localeName)} · '
    '${eventTime(dt)}';

/// Hero/subtitle date, kept short so it stays on one line:
/// "Sat 26 Sep · 6:30 PM".
String heroDateTime(AppLocalizations l, DateTime dt) =>
    '${shortDate(l, dt)} · ${eventTime(dt)}';

/// Screen title date: "Wednesday, 23 September", "23 Eylül Çarşamba".
String todayTitle(AppLocalizations l) => _titleDate(l, DateTime.now());

String _titleDate(AppLocalizations l, DateTime dt) =>
    _capitalised(_format(l, l.datePatternTitle, dt));

/// prayer_cache stores `gregorianDate` as dd.MM.yyyy.
String? gregorianTitle(AppLocalizations l, String? raw) {
  if (raw == null) return null;
  final parts = raw.split('.');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || m < 1 || m > 12) return null;
  return _titleDate(l, DateTime(y, m, d));
}

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
String? hijriTitle(AppLocalizations l, String? raw) {
  if (raw == null) return null;
  final parts = raw.split('.');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || m < 1 || m > 12) return null;
  return '$d ${_hijriMonth(l, m)} $y';
}

String _hijriMonth(AppLocalizations l, int month) => switch (month) {
      1 => l.hijriMonth1,
      2 => l.hijriMonth2,
      3 => l.hijriMonth3,
      4 => l.hijriMonth4,
      5 => l.hijriMonth5,
      6 => l.hijriMonth6,
      7 => l.hijriMonth7,
      8 => l.hijriMonth8,
      9 => l.hijriMonth9,
      10 => l.hijriMonth10,
      11 => l.hijriMonth11,
      _ => l.hijriMonth12,
    };

/// "Saturday 26 September" — used as a detail-screen row title.
String longDate(AppLocalizations l, DateTime dt) =>
    _capitalised(_format(l, l.datePatternLong, dt));

/// "12 September" — the marriage service's "Submitted" date.
String dayMonth(AppLocalizations l, DateTime dt) =>
    _format(l, l.datePatternDayMonth, dt);

/// "1.8 MB", "240 KB", "1,8 Mo" — file sizes on the marriage service's file
/// card. Decimal units, as phones show them in their file pickers.
String fileSize(AppLocalizations l, int bytes) {
  if (bytes >= 1000 * 1000) {
    final mb = NumberFormat('0.0', l.localeName).format(bytes / (1000 * 1000));
    return l.sizeMegabytes(mb);
  }
  return l.sizeKilobytes('${(bytes / 1000).ceil()}');
}

/// "March 2024" — used for "Member since".
String monthYear(AppLocalizations l, DateTime dt) =>
    _format(l, l.datePatternMonthYear, dt);

/// Weekday and month as the date tiles show them: "WED" / "SEP",
/// "MER" / "SEPT", "ÇAR" / "EYL". intl's French abbreviations end in a full
/// stop ("mer.", "sept."), which has no place on a 58 px tile.
String badgeWeekday(AppLocalizations l, DateTime dt) =>
    upper(_format(l, 'EEE', dt).replaceAll('.', ''), l.localeName);

String badgeMonth(AppLocalizations l, DateTime dt) =>
    upper(_format(l, 'MMM', dt).replaceAll('.', ''), l.localeName);

// ── Recurring and prayer-linked events (spec §7.3) ──────────────────────────
// Every DateTime passed here is a mosque-clock time (event_schedule.dart).

const _weekdayKeys = ['', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// What the recurring badge means, for screen readers: "Repeats weekly".
String recurrenceSpoken(AppLocalizations l, EventRecurrence r) => switch (r) {
      EventRecurrence.weekly => l.repeatsWeekly,
      EventRecurrence.biweekly => l.repeatsBiweekly,
      EventRecurrence.monthly => l.repeatsMonthly,
      EventRecurrence.none => '',
    };

/// The cadence at the start of the when line: "Every Wednesday",
/// "Every 2 weeks", "Monthly".
String recurrenceWhen(
  AppLocalizations l,
  EventRecurrence r,
  DateTime session,
) =>
    switch (r) {
      EventRecurrence.weekly => l.everyWeekday(_weekdayKeys[session.weekday]),
      EventRecurrence.biweekly => l.everyTwoWeeks,
      EventRecurrence.monthly => l.monthly,
      EventRecurrence.none => '',
    };

/// Detail eyebrow: "WEEKLY PROGRAMME"; one-off events keep "EVENT".
String eventEyebrow(AppLocalizations l, EventRecurrence r) => switch (r) {
      EventRecurrence.weekly => l.weeklyProgrammeEyebrow,
      EventRecurrence.biweekly => l.biweeklyProgrammeEyebrow,
      EventRecurrence.monthly => l.monthlyProgrammeEyebrow,
      EventRecurrence.none => l.eventEyebrow,
    };

/// Detail repeat row: ("Every Wednesday", "Weekly programme").
(String, String) recurrenceRow(
  AppLocalizations l,
  EventRecurrence r,
  DateTime session,
) =>
    switch (r) {
      EventRecurrence.weekly => (
          l.everyWeekday(_weekdayKeys[session.weekday]),
          l.weeklyProgramme,
        ),
      EventRecurrence.biweekly => (
          l.everyOtherWeekday(_weekdayKeys[session.weekday]),
          l.biweeklyProgramme,
        ),
      EventRecurrence.monthly => (
          l.everyMonthOnDay(_ordinal(l, session.day)),
          l.monthlyProgramme,
        ),
      EventRecurrence.none => ('', ''),
    };

/// The day of the month as [AppLocalizations.everyMonthOnDay] expects it:
/// "5th" in English, "1er" / "5" in French, "5" in Turkish (the ARB adds
/// the full stop: "Her ayın 5. günü", which needs no vowel harmony).
String _ordinal(AppLocalizations l, int n) {
  switch (l.localeName) {
    case 'en':
      if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
      return switch (n % 10) {
        1 => '${n}st',
        2 => '${n}nd',
        3 => '${n}rd',
        _ => '${n}th',
      };
    case 'fr':
      return n == 1 ? '1er' : '$n';
    default:
      return '$n';
  }
}

/// "Wed 30 Sep", "mer. 30 sept.", "30 Eyl Çar".
String shortDate(AppLocalizations l, DateTime dt) =>
    _capitalised(_format(l, l.datePatternShort, dt));

/// "next: Wed 30 Sep".
String nextShort(AppLocalizations l, DateTime dt) =>
    l.nextOn(shortDate(l, dt));

/// "30 September".
String dayMonthLong(AppLocalizations l, DateTime dt) =>
    _format(l, l.datePatternDayMonth, dt);

/// The single plain-text line for a session, used where there is no room
/// for icons (the Community header, share text):
/// "Every Wednesday · 7:30 PM", "Fri 2 Oct · after Maghrib",
/// "Every Friday · after Maghrib", "Sat 26 Sep · 6:30 PM".
String sessionLine(AppLocalizations l, UpcomingEvent u) {
  final e = u.event;
  final lead = e.repeats.isRecurring
      ? recurrenceWhen(l, e.repeats, u.startsAt)
      : shortDate(l, u.startsAt);
  final prayer = e.startsAfterPrayer;
  final when =
      prayer == null ? eventTime(u.startsAt) : l.afterPrayerInline(prayer);
  return '$lead · $when';
}

/// The next session with its date: "Wed 30 Sep · 7:30 PM", or
/// "Fri 2 Oct · after Maghrib" when prayer-linked.
String nextSessionLine(AppLocalizations l, UpcomingEvent u) {
  final prayer = u.event.startsAfterPrayer;
  return prayer == null
      ? heroDateTime(l, u.startsAt)
      : '${shortDate(l, u.startsAt)} · ${l.afterPrayerInline(prayer)}';
}

/// Share text for an event: title, when, place, registration link, then a
/// line saying where it came from.
String eventShareText(AppLocalizations l, UpcomingEvent u) {
  final e = u.event;
  final location = e.location?.trim();
  return [
    e.title,
    e.repeats.isRecurring
        ? '${sessionLine(l, u)} (${nextShort(l, u.startsAt)})'
        : nextSessionLine(l, u),
    if (location != null && location.isNotEmpty) location,
    if (e.registrationUri != null) l.registerAt('${e.registrationUri}'),
    '',
    l.sharedFromApp(MosqueInfo.website),
    if (MosqueInfo.appStoreUrl.isNotEmpty) MosqueInfo.appStoreUrl,
  ].join('\n');
}
