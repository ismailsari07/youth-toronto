import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/reminder_settings.dart';
import 'package:myt_flutter/core/reminder_sync.dart';
import 'package:myt_flutter/core/siri_data_sync.dart';
import 'package:myt_flutter/features/registration/registration_text.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/formatters.dart';
import 'package:timezone/timezone.dart' as tz;

const _nb = ' ';

/// A row for [day] as prayer_cache stores it (12-hour with no AM/PM).
PrayerDay _row(DateTime day) => (
      date: mosqueDateKey(day),
      payload: PrayerCachePayload(
        dailyPrayerTimes: const [
          DailyPrayerItem(name: 'Fajr', time: '5:43', iqamah: '6:45'),
          DailyPrayerItem(name: 'Sunrise', time: '7:11'),
          DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: '1:45'),
          DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
          DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
          DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
        ],
        hijriDate: '23.4.1448',
        gregorianDate:
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}',
      ),
    );

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final tr = lookupAppLocalizations(const Locale('tr'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  setUpAll(() async {
    initMosqueTime();
    await initializeDateFormatting();
  });

  group('clockText', () {
    test('the owner\'s examples', () {
      expect(clockText('en', 16, 55), '4:55 PM');
      expect(clockText('tr', 16, 55), '16:55');
      expect(clockText('fr', 16, 55), '16${_nb}h${_nb}55');
    });

    test('midnight, noon, the morning, on the hour', () {
      expect(
        [for (final (h, m) in const [(0, 5), (5, 3), (12, 0), (12, 30), (13, 0), (23, 59)]) clockText('en', h, m)],
        ['12:05 AM', '5:03 AM', '12:00 PM', '12:30 PM', '1:00 PM', '11:59 PM'],
      );
      expect(
        [for (final (h, m) in const [(0, 5), (5, 3), (12, 0), (12, 30), (13, 0), (23, 59)]) clockText('tr', h, m)],
        ['00:05', '05:03', '12:00', '12:30', '13:00', '23:59'],
      );
      expect(
        [for (final (h, m) in const [(0, 5), (5, 3), (12, 0), (12, 30), (13, 0), (23, 59)]) clockText('fr', h, m)],
        ['0${_nb}h${_nb}05', '5${_nb}h${_nb}03', '12${_nb}h', '12${_nb}h${_nb}30', '13${_nb}h', '23${_nb}h${_nb}59'],
      );
    });

    test('a regional locale name reads as its language', () {
      expect(clockText('fr_CA', 16, 55), '16${_nb}h${_nb}55');
    });
  });

  group('every place that shows a time', () {
    test('prayer times, as stored in prayer_cache', () {
      expect(prayerClockText(en, 'Asr', '4:23'), '4:23 PM');
      expect(prayerClockText(tr, 'Asr', '4:23'), '16:23');
      expect(prayerClockText(fr, 'Asr', '4:23'), '16${_nb}h${_nb}23');
      expect(prayerClockText(tr, 'Fajr', '05:43'), '05:43');
      expect(prayerClockText(fr, 'Fajr', '05:43'), '5${_nb}h${_nb}43');
    });

    test('an unreadable stored time is shown as it is, never guessed', () {
      expect(prayerClockText(tr, 'Asr', 'kapalı'), 'kapalı');
    });

    test('events and registration deadlines', () {
      final at = tz.TZDateTime(mosqueTz, 2026, 9, 30, 19, 30);
      expect(eventTime(en, at), '7:30 PM');
      expect(eventTime(tr, at), '19:30');
      expect(eventTime(fr, at), '19${_nb}h${_nb}30');
      expect(heroDateTime(tr, at), endsWith('· 19:30'));
      expect(eventCardDate(fr, at), endsWith('· 19${_nb}h${_nb}30'));
      expect(registrationWhen(tr, at.toUtc()), endsWith(', 19:30'));
      expect(registrationWhen(en, at.toUtc()), endsWith(', 7:30 PM'));
    });

    test("the reminders' text", () {
      for (final (l, iqamah) in [
        (en, '1:45 PM'),
        (tr, '13:45'),
        (fr, '13${_nb}h${_nb}45'),
      ]) {
        final now = tz.TZDateTime(mosqueTz, 2026, 10, 4, 3);
        final dhuhr = buildReminders(
          [_row(DateTime(2026, 10, 4))],
          const ReminderSettings(),
          l,
          now: now,
          sound: ReminderSound.standard,
        ).firstWhere((r) => r.id % 10 == 1);
        expect(dhuhr.body, endsWith(iqamah), reason: l.localeName);
      }
    });
  });

  group('a time inside a sentence', () {
    test("Turkish adds the suffix of the last number said, like Siri's", () {
      for (final (clock, said) in [
        ('13:00', "13:00'te"),
        ('16:00', "16:00'da"),
        ('20:00', "20:00'de"),
        ('00:00', "00:00'da"),
        ('13:07', "13:07'de"),
        ('13:30', "13:30'da"),
        ('13:40', "13:40'ta"),
        ('13:50', "13:50'de"),
        ('13:05', "13:05'te"),
        ('13:09', "13:09'da"),
      ]) {
        expect(clockInSentence(tr, clock), said);
      }
    });

    test('English and French are unchanged: their word comes before the time', () {
      expect(clockInSentence(en, '1:00 PM'), '1:00 PM');
      expect(clockInSentence(fr, '13${_nb}h'), '13${_nb}h');
    });
  });

  // Toronto: 8 March 2026 starts daylight time, 1 November 2026 ends it.
  group('days around the clock changes', () {
    final dstDays = {
      DateTime(2026, 3, 7): -5, // EST
      DateTime(2026, 3, 8): -4, // EDT from 2:00
      DateTime(2026, 10, 31): -4, // EDT
      DateTime(2026, 11, 1): -5, // EST from 2:00
    };

    for (final MapEntry(key: day, value: offset) in dstDays.entries) {
      test('${mosqueDateKey(day)}: same wall clock, same instant, any language', () {
        final at = prayerMoment(day, 'Dhuhr', '1:11')!;
        expect(at.toUtc().hour, 13 - offset, reason: 'the instant');

        final now = tz.TZDateTime(mosqueTz, day.year, day.month, day.day, 0, 30);
        final atOf = {
          for (final l in [en, tr, fr])
            l.localeName: buildReminders(
              [_row(day)],
              const ReminderSettings(),
              l,
              now: now,
              sound: ReminderSound.standard,
            ).map((r) => r.at.millisecondsSinceEpoch).toList(),
        };
        expect(atOf['en'], isNotEmpty);
        expect(atOf['tr'], atOf['en'], reason: 'language never moves a reminder');
        expect(atOf['fr'], atOf['en'], reason: 'language never moves a reminder');
      });

      test('${mosqueDateKey(day)}: Siri gets instants and all three texts', () {
        final now = tz.TZDateTime(mosqueTz, day.year, day.month, day.day, 0, 30);
        final doc = buildPrayers([_row(day)], now, firstDay: 0, dayCount: 1);
        final dhuhr = ((doc['days']! as List).single as Map)['prayers'][2] as Map;
        expect(dhuhr['time'], {'en': '1:11 PM', 'tr': '13:11', 'fr': '13${_nb}h${_nb}11'});
        expect(
          DateTime.fromMillisecondsSinceEpoch((dhuhr['at'] as int) * 1000, isUtc: true).hour,
          13 - offset,
        );
      });
    }

    test('an event after the change keeps its wall clock', () {
      final before = tz.TZDateTime(mosqueTz, 2026, 10, 28, 19, 30);
      final after = tz.TZDateTime(mosqueTz, 2026, 11, 4, 19, 30);
      expect(eventTime(tr, before), eventTime(tr, after));
      expect(eventTime(fr, before), eventTime(fr, after));
      expect(before.timeZoneOffset.inHours, -4);
      expect(after.timeZoneOffset.inHours, -5);
    });

    test('a deadline given as an instant reads on the mosque\'s clock', () {
      // 23:30 UTC is 19:30 before the change and 18:30 after it.
      expect(registrationWhen(tr, DateTime.utc(2026, 10, 28, 23, 30)), endsWith('19:30'));
      expect(registrationWhen(tr, DateTime.utc(2026, 11, 4, 23, 30)), endsWith('18:30'));
    });
  });

  test("Flutter and Swift agree on the document's version", () {
    final swift = File('ios/Runner/Siri/SiriData.swift').readAsStringSync();
    expect(swift, contains('static let version = ${SiriDataSync.version}'));
  });
}
