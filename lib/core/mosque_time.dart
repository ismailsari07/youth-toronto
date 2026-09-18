import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Prayer logic runs on the mosque's clock (America/Toronto), never the
// device's, so a user anywhere sees and is reminded of the mosque schedule.

tz.Location? _mosqueTz;

/// Loads the time-zone database. Called first in main(); safe to repeat.
void initMosqueTime() {
  if (_mosqueTz != null) return;
  tz_data.initializeTimeZones();
  _mosqueTz = tz.getLocation('America/Toronto');
}

tz.Location get mosqueTz {
  if (_mosqueTz == null) initMosqueTime();
  return _mosqueTz!;
}

tz.TZDateTime mosqueNow() => tz.TZDateTime.now(mosqueTz);

/// `yyyy-MM-dd` of [day] — the key format of prayer_cache.date.
String mosqueDateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// 24-hour (hour, minute) for a stored prayer time, or null if unparseable.
///
/// pape-api stores afternoon/evening times as 12-hour clock with no AM/PM
/// ("2:00" for Dhuhr iqamah = 2 PM). Only Fajr and Sunrise are morning times.
/// Hours of 13+ are already 24-hour (e.g. a future admin override) and are
/// kept as-is.
({int hour, int minute})? prayerClock(String name, String hhmm) {
  final parts = hhmm.trim().split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  if (h >= 13) return (hour: h, minute: m);

  switch (name) {
    case 'Fajr':
    case 'Sunrise':
      return (hour: h, minute: m);
    case 'Dhuhr':
      // Around noon: 11:xx / 12:xx are as written; 1:xx–10:xx are PM.
      return (hour: h <= 10 ? h + 12 : h, minute: m);
    case 'Asr':
    case 'Maghrib':
    case 'Isha':
      return (hour: h < 12 ? h + 12 : h, minute: m);
    default:
      return (hour: h, minute: m);
  }
}

/// The instant a prayer time falls on the mosque's calendar [day].
tz.TZDateTime? prayerMoment(DateTime day, String name, String hhmm) {
  final clock = prayerClock(name, hhmm);
  if (clock == null) return null;
  return tz.TZDateTime(
    mosqueTz,
    day.year,
    day.month,
    day.day,
    clock.hour,
    clock.minute,
  );
}
