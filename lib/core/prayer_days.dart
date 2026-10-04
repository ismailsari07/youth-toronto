import 'models.dart';
import 'mosque_time.dart';

/// One prayer_cache row: its `yyyy-MM-dd` date and payload.
typedef PrayerDay = ({String date, PrayerCachePayload payload});

/// The schedule for [count] consecutive mosque-calendar days, starting
/// [first] days from [now]'s date (0 = today, -1 = yesterday). [offset] is
/// each day's distance from today.
///
/// A day with no row of its own (prayer_cache only holds up to today) uses
/// the latest known day's times; days before every known row are skipped.
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
    final key = mosqueDateKey(day);
    final payload = byDate[key] ?? _latestOnOrBefore(days, key);
    if (payload == null) continue;
    result.add((offset: i, day: day, payload: payload));
  }
  return result;
}

PrayerCachePayload? _latestOnOrBefore(List<PrayerDay> days, String key) {
  PrayerCachePayload? latest;
  for (final d in days) {
    // yyyy-MM-dd strings compare in date order.
    if (d.date.compareTo(key) <= 0) latest = d.payload;
  }
  return latest;
}
