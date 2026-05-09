import 'models.dart';

DateTime _parseTime(String timeStr, DateTime date) {
  final parts = timeStr.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime(date.year, date.month, date.day, hour, minute);
}

NextPrayer getNextPrayer(List<DailyPrayerItem> prayers) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final filtered = prayers.where((p) => p.name != 'Sunrise').toList();

  for (final prayer in filtered) {
    final prayerTime = _parseTime(prayer.time, today);
    if (prayerTime.isAfter(now)) {
      return NextPrayer(
        name: prayer.name,
        time: prayer.time,
        iqamah: prayer.iqamah,
        minutesUntil: prayerTime.difference(now).inMinutes,
      );
    }
  }

  // All prayers have passed — wrap to Fajr tomorrow
  final fajr = filtered.firstWhere((p) => p.name == 'Fajr');
  final fajrTomorrow = _parseTime(fajr.time, today.add(const Duration(days: 1)));
  return NextPrayer(
    name: fajr.name,
    time: fajr.time,
    iqamah: fajr.iqamah,
    minutesUntil: fajrTomorrow.difference(now).inMinutes,
  );
}
