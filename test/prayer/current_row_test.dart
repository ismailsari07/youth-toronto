import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_utils.dart';
import 'package:timezone/timezone.dart' as tz;

/// One prayer_cache day as pape-api stores it: afternoon and evening times
/// on a 12-hour clock with no AM/PM.
const _day = [
  DailyPrayerItem(name: 'Fajr', time: '5:43', iqamah: '6:45'),
  DailyPrayerItem(name: 'Sunrise', time: '7:11'),
  DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: '2:00'),
  DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
  DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
  DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
];

void main() {
  setUpAll(initMosqueTime);

  /// The highlighted row at h:m on Monday 5 October 2026 in Toronto.
  String? at(int h, int m) => currentTimetableRow(
        _day,
        now: tz.TZDateTime(mosqueTz, 2026, 10, 5, h, m),
      );

  test('after midnight, before Fajr: still the night\'s Isha', () {
    expect(at(0, 30), 'Isha');
    expect(at(5, 42), 'Isha');
  });

  test('Fajr from its athan until sunrise', () {
    expect(at(5, 43), 'Fajr');
    expect(at(7, 10), 'Fajr');
  });

  test('Sunrise until Dhuhr: the Sunrise row, never Fajr', () {
    expect(at(7, 11), 'Sunrise');
    expect(at(10, 0), 'Sunrise');
    expect(at(13, 10), 'Sunrise');
  });

  test('each later prayer from its athan to the next', () {
    expect(at(13, 11), 'Dhuhr');
    expect(at(13, 20), 'Dhuhr'); // Asr is next, Dhuhr is highlighted
    expect(at(16, 22), 'Dhuhr');
    expect(at(16, 23), 'Asr');
    expect(at(19, 1), 'Asr');
    expect(at(19, 2), 'Maghrib');
    expect(at(20, 18), 'Maghrib');
    expect(at(20, 19), 'Isha');
  });

  test('after Isha until midnight: Isha', () {
    expect(at(22, 0), 'Isha');
    expect(at(23, 59), 'Isha');
  });
}
