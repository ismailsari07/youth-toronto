import 'models.dart';
import 'mosque_time.dart';

/// One prayer_cache row: its `yyyy-MM-dd` date and payload.
typedef PrayerDay = ({String date, PrayerCachePayload payload});

/// The days among [count] consecutive mosque-calendar days, starting
/// [first] days from [now]'s date (0 = today, -1 = yesterday), that have a
/// real row of their own. [offset] is each day's distance from today.
///
/// The owner's rule: a prayer notification must never fire at a wrong time.
/// A day without its own row is left out, never filled from another day, so
/// when the data runs out the schedule simply ends. A row whose Diyanet date
/// (`gregorianDate`, DD.MM.YYYY) isn't its own date is left out too, the
/// same check the database makes (pape-admin `prayer_source_valid`).
/// Shared by the reminders and the home-screen widget, so both always agree.
List<({int offset, DateTime day, PrayerCachePayload payload})> scheduleDays(
  List<PrayerDay> days,
  DateTime now, {
  int first = 0,
  required int count,
}) {
  final byDate = {for (final d in days) d.date: d.payload};
  final result = <({int offset, DateTime day, PrayerCachePayload payload})>[];
  for (var i = first; i < first + count; i++) {
    // Calendar-day step (not 24h), so a DST change can't skip a date.
    final day = DateTime(now.year, now.month, now.day + i);
    final payload = byDate[mosqueDateKey(day)];
    if (payload == null || payload.gregorianDate.trim() != diyanetDate(day)) {
      continue;
    }
    result.add((offset: i, day: day, payload: payload));
  }
  return result;
}

/// [day] as Diyanet writes it: `DD.MM.YYYY`.
String diyanetDate(DateTime day) =>
    '${day.day.toString().padLeft(2, '0')}.'
    '${day.month.toString().padLeft(2, '0')}.'
    '${day.year.toString().padLeft(4, '0')}';
