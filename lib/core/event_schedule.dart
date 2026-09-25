import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'mosque_time.dart';

// Event dates run on the mosque's clock (America/Toronto), like prayers: a
// weekly 7:30 PM programme is 7:30 PM at the mosque on every date, through
// both DST changes, wherever the phone happens to be.

/// An event paired with the start of its next session (or its only one).
class UpcomingEvent {
  const UpcomingEvent(this.event, this.startsAt);

  final YouthEvent event;

  /// Mosque-clock start of the session to show. For a one-off event this is
  /// its stored date; for a recurring one, the next session from today.
  final tz.TZDateTime startsAt;
}

/// Midnight today on the mosque's calendar.
tz.TZDateTime mosqueStartOfDay(tz.TZDateTime now) =>
    tz.TZDateTime(mosqueTz, now.year, now.month, now.day);

/// The session to show for [event] as of [now].
///
/// One-off events return their stored start. Recurring events step forward
/// from the stored first session by calendar dates — 7 days, 14 days or one
/// month — to the first session on or after today (so today's session stays
/// listed all day, like a one-off), then rebuild the stored wall-clock time
/// on that date. Stepping dates rather than adding 7×24 hours is what keeps
/// the time from drifting by an hour across a DST change. Monthly sessions
/// count from the original day and clamp to the month's last day, so the
/// 31st becomes the 30th in April but is the 31st again in May.
tz.TZDateTime nextOccurrence(YouthEvent event, tz.TZDateTime now) {
  final first = tz.TZDateTime.from(event.dateTime, mosqueTz);
  final repeats = event.repeats;
  if (!repeats.isRecurring) return first;

  // Pure calendar dates in UTC, so date arithmetic never meets a DST gap.
  final firstDate = DateTime.utc(first.year, first.month, first.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  if (!firstDate.isBefore(today)) return first;

  final DateTime date;
  switch (repeats) {
    case EventRecurrence.weekly:
    case EventRecurrence.biweekly:
      final step = repeats == EventRecurrence.weekly ? 7 : 14;
      final days = today.difference(firstDate).inDays;
      final steps = (days + step - 1) ~/ step;
      date = DateTime.utc(
        firstDate.year,
        firstDate.month,
        firstDate.day + steps * step,
      );
    case EventRecurrence.monthly:
      var months =
          (today.year - firstDate.year) * 12 + today.month - firstDate.month;
      var candidate = _monthsAfter(firstDate, months);
      if (candidate.isBefore(today)) {
        candidate = _monthsAfter(firstDate, ++months);
      }
      date = candidate;
    case EventRecurrence.none:
      return first;
  }
  return tz.TZDateTime(
    mosqueTz,
    date.year,
    date.month,
    date.day,
    first.hour,
    first.minute,
  );
}

/// [start]'s day of the month, [months] later, clamped to that month's end.
DateTime _monthsAfter(DateTime start, int months) {
  final lastDay = DateTime.utc(start.year, start.month + months + 1, 0).day;
  final day = start.day <= lastDay ? start.day : lastDay;
  return DateTime.utc(start.year, start.month + months, day);
}

/// The events to list as of [now]: every recurring event at its next
/// session, one-off events from today onward, soonest first.
List<UpcomingEvent> upcomingEvents(
  Iterable<YouthEvent> events,
  tz.TZDateTime now,
) {
  final cutoff = mosqueStartOfDay(now);
  final upcoming = [
    for (final e in events)
      if (!nextOccurrence(e, now).isBefore(cutoff))
        UpcomingEvent(e, nextOccurrence(e, now)),
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return upcoming;
}

/// `maghrib` → `Maghrib`, the name prayer_cache uses.
String prayerName(String key) =>
    key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';

/// When a prayer-linked session on [day] should roughly begin: that day's
/// iqamah (or the athan, if no iqamah is listed) plus 10 minutes for the
/// jama'ah, rounded up to the next 5 minutes.
///
/// Returns null unless [cache] is the prayer data for [day] itself. Prayer
/// times are only ever known for today and past days, so a future session
/// gets no clock time at all — nothing is estimated from another day.
tz.TZDateTime? prayerLinkedEstimate({
  required String prayerKey,
  required DateTime day,
  required PrayerCachePayload? cache,
}) {
  if (cache == null || !_isCacheFor(cache, day)) return null;
  final name = prayerName(prayerKey);
  DailyPrayerItem? prayer;
  for (final p in cache.dailyPrayerTimes) {
    if (p.name == name) prayer = p;
  }
  if (prayer == null) return null;
  final iqamah = prayer.iqamah?.trim();
  final begins = (iqamah != null && iqamah.isNotEmpty
          ? prayerMoment(day, name, iqamah)
          : null) ??
      prayerMoment(day, name, prayer.time);
  if (begins == null) return null;
  final after = begins.add(const Duration(minutes: 10));
  final roundUp = (5 - after.minute % 5) % 5;
  return after.add(Duration(minutes: roundUp));
}

/// prayer_cache's `gregorianDate` is dd.MM.yyyy.
bool _isCacheFor(PrayerCachePayload cache, DateTime day) {
  final parts = cache.gregorianDate.split('.');
  if (parts.length != 3) return false;
  return int.tryParse(parts[0]) == day.day &&
      int.tryParse(parts[1]) == day.month &&
      int.tryParse(parts[2]) == day.year;
}
