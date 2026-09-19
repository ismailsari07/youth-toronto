import 'models.dart';
import 'mosque_time.dart';

/// The next prayer (Sunrise excluded) on the mosque's clock. After Isha it
/// wraps to tomorrow's Fajr, using today's time as the estimate.
NextPrayer getNextPrayer(List<DailyPrayerItem> prayers) {
  final now = mosqueNow();
  final today = DateTime(now.year, now.month, now.day);

  final filtered = prayers.where((p) => p.name != 'Sunrise').toList();

  for (final prayer in filtered) {
    final moment = prayerMoment(today, prayer.name, prayer.time);
    if (moment != null && moment.isAfter(now)) {
      return NextPrayer(
        name: prayer.name,
        time: prayer.time,
        iqamah: prayer.iqamah,
        minutesUntil: moment.difference(now).inMinutes,
      );
    }
  }

  // All prayers have passed — wrap to Fajr tomorrow
  final fajr = filtered.firstWhere((p) => p.name == 'Fajr');
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final fajrTomorrow = prayerMoment(tomorrow, fajr.name, fajr.time);
  return NextPrayer(
    name: fajr.name,
    time: fajr.time,
    iqamah: fajr.iqamah,
    minutesUntil: fajrTomorrow?.difference(now).inMinutes ?? 0,
  );
}

/// The prayer window the mosque is currently inside: from [current]'s athan to
/// [next]'s athan, with [progress] the elapsed fraction (spec §6).
class PrayerWindow {
  const PrayerWindow({
    required this.current,
    required this.next,
    required this.progress,
    required this.secondsToNext,
  });

  final DailyPrayerItem current;
  final DailyPrayerItem next;
  final double progress;
  final int secondsToNext;
}

/// Sunrise is excluded: it marks the end of the Fajr window, not a prayer.
PrayerWindow? currentPrayerWindow(List<DailyPrayerItem> prayers) {
  final list = prayers.where((p) => p.name != 'Sunrise').toList();
  if (list.length < 2) return null;

  final now = mosqueNow();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  for (var i = 0; i < list.length; i++) {
    final start = prayerMoment(today, list[i].name, list[i].time);
    if (start == null) continue;

    if (now.isBefore(start)) {
      // Before the first prayer of the day: the window began with yesterday's
      // last prayer (times shift by a minute or two, which is immaterial here).
      final previous = i == 0 ? list.last : list[i - 1];
      final from = prayerMoment(
        i == 0 ? yesterday : today,
        previous.name,
        previous.time,
      );
      if (from == null) continue;
      return _window(previous, list[i], from, start, now);
    }

    final isLast = i == list.length - 1;
    final endPrayer = isLast ? list.first : list[i + 1];
    final end = prayerMoment(
      isLast ? tomorrow : today,
      endPrayer.name,
      endPrayer.time,
    );
    if (end == null) continue;
    if (now.isBefore(end)) {
      return _window(list[i], endPrayer, start, end, now);
    }
  }
  return null;
}

PrayerWindow _window(
  DailyPrayerItem current,
  DailyPrayerItem next,
  DateTime from,
  DateTime to,
  DateTime now,
) {
  final total = to.difference(from).inSeconds;
  final elapsed = now.difference(from).inSeconds;
  return PrayerWindow(
    current: current,
    next: next,
    progress: total <= 0 ? 0 : (elapsed / total).clamp(0.0, 1.0),
    secondsToNext: to.difference(now).inSeconds,
  );
}
