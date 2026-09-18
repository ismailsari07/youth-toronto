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
