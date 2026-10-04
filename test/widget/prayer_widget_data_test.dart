import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/prayer_widget_sync.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:timezone/timezone.dart' as tz;

/// One prayer_cache row as pape-api stores it: afternoon and evening times
/// on a 12-hour clock with no AM/PM.
PrayerCachePayload _payload({String fajr = '5:43'}) => PrayerCachePayload(
  dailyPrayerTimes: [
    DailyPrayerItem(name: 'Fajr', time: fajr, iqamah: '6:45'),
    const DailyPrayerItem(name: 'Sunrise', time: '7:11'),
    const DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: '2:00'),
    const DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
    const DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
    const DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
  ],
  hijriDate: '23.4.1448',
  gregorianDate: '04.10.2026',
);

void main() {
  setUpAll(initMosqueTime);

  // Sunday 4 October 2026, 10:00 in Toronto.
  late tz.TZDateTime now;
  // prayer_cache holds yesterday and today; later days reuse today's times.
  late List<PrayerDay> days;

  setUp(() {
    now = tz.TZDateTime(mosqueTz, 2026, 10, 4, 10);
    days = [
      (date: '2026-10-03', payload: _payload(fajr: '5:42')),
      (date: '2026-10-04', payload: _payload()),
    ];
  });

  Map<String, Object?> build(String lang) =>
      buildPrayerWidgetData(days, lookupAppLocalizations(Locale(lang)), now);

  List<Map<String, Object?>> prayers(Map<String, Object?> data) =>
      (data['prayers']! as List).cast<Map<String, Object?>>();

  test('covers yesterday plus the next 7 days, six times a day', () {
    final list = prayers(build('en'));
    final dates = list.map((p) => p['day']).toSet().toList();
    expect(dates, [
      '2026-10-03',
      '2026-10-04',
      '2026-10-05',
      '2026-10-06',
      '2026-10-07',
      '2026-10-08',
      '2026-10-09',
      '2026-10-10',
    ]);
    expect(list, hasLength(8 * 6));
  });

  test('prayers are in time order, as Unix seconds on the mosque clock', () {
    final list = prayers(build('en'));
    final at = list.map((p) => p['at']! as int).toList();
    expect(at, [...at]..sort());

    // Today's Fajr: 5:43 AM in Toronto (EDT, UTC−4) = 09:43 UTC.
    final fajr = list.firstWhere(
      (p) => p['day'] == '2026-10-04' && p['key'] == 'Fajr',
    );
    expect(
      fajr['at'],
      DateTime.utc(2026, 10, 4, 9, 43).millisecondsSinceEpoch ~/ 1000,
    );
    // Yesterday kept its own row's time.
    final yesterday = list.firstWhere(
      (p) => p['day'] == '2026-10-03' && p['key'] == 'Fajr',
    );
    expect(yesterday['time'], '5:42 AM');
  });

  test('times are normalised to 12-hour with AM/PM in every language', () {
    for (final lang in ['en', 'fr', 'tr']) {
      final today = prayers(
        build(lang),
      ).where((p) => p['day'] == '2026-10-04').map((p) => p['time']).toList();
      expect(today, [
        '5:43 AM',
        '7:11 AM',
        '1:11 PM',
        '4:23 PM',
        '7:02 PM',
        '8:19 PM',
      ]);
    }
  });

  test('names and labels follow the app language', () {
    String names(String lang) => prayers(
      build(lang),
    ).where((p) => p['day'] == '2026-10-04').map((p) => p['name']).join(', ');

    expect(names('en'), 'Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha');
    expect(names('fr'), 'Fajr, Lever du soleil, Dhohr, Asr, Maghrib, Icha');
    expect(names('tr'), 'İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı');

    final tr = build('tr');
    expect(tr['locale'], 'tr');
    expect((tr['strings']! as Map)['nextPrayer'], 'SIRADAKİ NAMAZ');
    final asr = prayers(tr).firstWhere((p) => p['key'] == 'Asr');
    expect(asr['athan'], 'Ezan 4:23 PM');
    expect(asr['iqamah'], 'Cemaat 4:45 PM');
  });

  test('Sunrise carries no iqamah line', () {
    final sunrise = prayers(
      build('en'),
    ).firstWhere((p) => p['key'] == 'Sunrise');
    expect(sunrise.containsKey('iqamah'), isFalse);
  });

  test('is plain JSON the widget can decode', () {
    final data = build('en');
    final round = jsonDecode(jsonEncode(data)) as Map<String, Object?>;
    expect(round['version'], 1);
    expect(round['prayers'], hasLength(48));
  });

  test('no rows at all gives no prayers rather than invented times', () {
    days = [];
    expect(prayers(build('en')), isEmpty);
  });
}
