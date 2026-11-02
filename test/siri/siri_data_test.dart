import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/eid.dart';
import 'package:myt_flutter/core/event_schedule.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/siri_data_sync.dart';
import 'package:myt_flutter/shared/formatters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;

EidPrayerEntry _eidEntry(String date) => EidPrayerEntry(
      date: date,
      time: '06:19:00',
      hijriDate: '1 Şevval 1448',
      firstIqamah: '08:00',
      secondIqamah: '08:30',
    );

PrayerCachePayload _payload(DateTime day, {String? jumaa, EidPrayerTimes? eid}) =>
    PrayerCachePayload(
      dailyPrayerTimes: const [
        DailyPrayerItem(name: 'Fajr', time: '5:43', iqamah: '6:45'),
        DailyPrayerItem(name: 'Sunrise', time: '7:11'),
        DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: '2:00'),
        DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
        DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
        DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
      ],
      hijriDate: '23.4.1448',
      gregorianDate: diyanetDate(day),
      jumaaPrayerTime: jumaa,
      eidPrayerTimes: eid,
    );

PrayerDay _row(DateTime day, {String? jumaa, EidPrayerTimes? eid}) =>
    (date: mosqueDateKey(day), payload: _payload(day, jumaa: jumaa, eid: eid));

YouthEvent _event(String id, DateTime start, {String recurrence = 'none', String? after}) =>
    YouthEvent(
      id: id,
      title: 'Etkinlik $id',
      dateTime: tz.TZDateTime(mosqueTz, start.year, start.month, start.day, start.hour, start.minute).toUtc(),
      isFree: true,
      attendingCount: 0,
      category: 'community',
      recurrence: recurrence,
      isPublished: true,
      startsAfterPrayer: after,
    );

void main() {
  setUpAll(() async {
    initMosqueTime();
    await initializeDateFormatting();
  });

  // Sunday 8 November 2026, 10:00 in Toronto.
  tz.TZDateTime now() => tz.TZDateTime(mosqueTz, 2026, 11, 8, 10);

  Map<String, Object?> prayers(List<PrayerDay> days, {tz.TZDateTime? at}) =>
      buildPrayers(days, at ?? now(), firstDay: -1, dayCount: 15);

  List<Map<String, dynamic>> daysOf(Map<String, Object?> doc) =>
      (doc['days']! as List).cast<Map<String, dynamic>>();

  group('prayers document', () {
    test('is versioned and survives JSON', () {
      final doc = jsonDecode(jsonEncode(prayers([_row(DateTime(2026, 11, 8))])));
      expect(doc['version'], 1);
      expect(doc['writtenAt'], now().millisecondsSinceEpoch ~/ 1000);
    });

    test('has the app\'s times and the matching instants', () {
      final day = daysOf(prayers([_row(DateTime(2026, 11, 8))])).single;
      expect(day['date'], '2026-11-08');
      final list = (day['prayers'] as List).cast<Map<String, dynamic>>();
      expect(list.map((p) => p['key']), ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
      final dhuhr = list[2];
      expect(dhuhr['time'], '1:11 PM');
      expect(dhuhr['iqamah'], '2:00 PM');
      expect(dhuhr['at'], tz.TZDateTime(mosqueTz, 2026, 11, 8, 13, 11).millisecondsSinceEpoch ~/ 1000);
      expect(dhuhr['iqamahAt'], tz.TZDateTime(mosqueTz, 2026, 11, 8, 14).millisecondsSinceEpoch ~/ 1000);
      expect(list[1].containsKey('iqamah'), isFalse, reason: 'Sunrise');
    });

    test('never fills in a missing day', () {
      final days = daysOf(prayers([_row(DateTime(2026, 11, 8)), _row(DateTime(2026, 11, 10))]));
      expect(days.map((d) => d['date']), ['2026-11-08', '2026-11-10']);
    });

    test('drops a row whose Diyanet date isn\'t its own', () {
      final wrong = (date: '2026-11-08', payload: _payload(DateTime(2026, 11, 9)));
      expect(daysOf(prayers([wrong])), isEmpty);
    });

    test('Jumu\'ah only on a Friday, from that Friday\'s row', () {
      final days = daysOf(prayers([
        _row(DateTime(2026, 11, 9), jumaa: '1:00'), // Monday: "upcoming Friday"
        _row(DateTime(2026, 11, 13), jumaa: '1:30'), // Friday
      ]));
      expect(days[0].containsKey('jumuah'), isFalse);
      expect(days[1]['jumuah']['time'], '1:30 PM');
      expect(
        days[1]['jumuah']['at'],
        tz.TZDateTime(mosqueTz, 2026, 11, 13, 13, 30).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('a DST day keeps the right instants', () {
      // 1 Nov 2026, clocks back at 2:00: Fajr 5:43 is EST, -5.
      final at = tz.TZDateTime(mosqueTz, 2026, 11, 1, 1);
      final day = daysOf(prayers([_row(DateTime(2026, 11, 1))], at: at)).single;
      final fajr = (day['prayers'] as List).first as Map<String, dynamic>;
      expect(fajr['at'], DateTime.utc(2026, 11, 1, 10, 43).millisecondsSinceEpoch ~/ 1000);
    });

    group('Eid', () {
      EidPrayerTimes eid(String fitr, String adha) =>
          EidPrayerTimes(eidFitr: _eidEntry(fitr), eidAdha: _eidEntry(adha));

      test('from today\'s row, as the morning prayers they are', () {
        final doc = prayers([_row(DateTime(2026, 11, 8), eid: eid('9 Mart 2027 Salı', '16 Mayıs 2027 Pazar'))]);
        final list = (doc['eid']! as List).cast<Map<String, dynamic>>();
        expect(list.map((e) => e['which']), ['fitr', 'adha']);
        expect(list[0]['date'], '2027-03-09');
        expect(list[0]['first'], '8:00 AM');
        expect(list[0]['second'], '8:30 AM');
        expect(list[0]['firstAt'], tz.TZDateTime(mosqueTz, 2027, 3, 9, 8).millisecondsSinceEpoch ~/ 1000);
      });

      test('none without a row for today', () {
        final doc = prayers([_row(DateTime(2026, 11, 9), eid: eid('9 Mart 2027 Salı', '16 Mayıs 2027 Pazar'))]);
        expect(doc['eid'], isEmpty);
      });

      test('an unreadable date is left out', () {
        final doc = prayers([_row(DateTime(2026, 11, 8), eid: eid('yakında', '16 Mayıs 2027 Pazar'))]);
        expect((doc['eid']! as List).single['which'], 'adha');
      });

      test('parses the feed\'s Turkish date', () {
        expect(parseEidDate('20 Mart 2026 Cuma'), DateTime(2026, 3, 20));
        expect(parseEidDate('27 Mayıs 2026 Çarşamba'), DateTime(2026, 5, 27));
        expect(parseEidDate('garbage'), isNull);
      });
    });
  });

  group('events document', () {
    List<Map<String, dynamic>> items(Iterable<YouthEvent> events) =>
        (buildEvents(events, now())['items']! as List).cast<Map<String, dynamic>>();

    test('stamps the fetch and is versioned', () {
      final doc = buildEvents(const [], now());
      expect(doc['version'], 1);
      expect(doc['fetchedAt'], now().millisecondsSinceEpoch ~/ 1000);
      expect(doc['items'], isEmpty);
    });

    test('says what the app says, in all three languages', () {
      // Wednesday 11 November, after Maghrib, weekly.
      final item = items([_event('a', DateTime(2026, 11, 11, 19), recurrence: 'weekly', after: 'maghrib')]).first;
      expect(item['when']['tr'], 'Her Çarşamba · akşam namazından sonra');
      expect(item['when']['en'], 'Every Wednesday · after Maghrib');
      expect(item['when']['fr'], 'Tous les mercredis · après le Maghrib');
      expect(item['next'], isNotNull);
    });

    test('a prayer-linked session has no clock time in its wording', () {
      final item = items([_event('a', DateTime(2026, 11, 11, 19), after: 'maghrib')]).first;
      for (final line in (item['when'] as Map).values) {
        expect(line, isNot(contains('PM')));
        expect(line, isNot(contains('about')));
      }
    });

    test('a one-off has no "next"', () {
      expect(items([_event('a', DateTime(2026, 11, 20, 18, 30))]).first.containsKey('next'), isFalse);
    });

    test('keeps later sessions of a recurring event, in order, within limits', () {
      final list = items([
        _event('w', DateTime(2026, 11, 11, 19), recurrence: 'weekly'),
        _event('o', DateTime(2026, 11, 12, 18)),
      ]);
      expect(list.first['id'], 'w');
      expect(list[1]['id'], 'o');
      expect(list.where((i) => i['id'] == 'w').length, greaterThanOrEqualTo(6));
      final starts = list.map((i) => i['startsAt'] as int).toList();
      expect(starts, [...starts]..sort());
      expect(list.length, lessThanOrEqualTo(SiriDataSync.maxEvents));
      expect(items([
        for (var i = 0; i < 6; i++)
          _event('w$i', DateTime(2026, 11, 9 + i, 19), recurrence: 'weekly'),
      ]).length, SiriDataSync.maxEvents);
    });

    test('weekly sessions keep the wall clock across a DST change', () {
      // First session in October; clocks go back on 1 November.
      final list = items([_event('w', DateTime(2026, 10, 28, 19), recurrence: 'weekly')]);
      final first = tz.TZDateTime.fromMillisecondsSinceEpoch(mosqueTz, (list[0]['startsAt'] as int) * 1000);
      expect(first.hour, 19);
      expect(first.day, 11);
    });

    test('leaves out what the app leaves out', () {
      expect(items([_event('old', DateTime(2026, 11, 1, 18))]), isEmpty);
      expect(upcomingEvents([_event('old', DateTime(2026, 11, 1, 18))], now()), isEmpty);
    });

    test('agrees with the app\'s own line', () {
      final e = _event('a', DateTime(2026, 11, 20, 18, 30));
      final item = items([e]).first;
      expect(item['day'], '2026-11-20');
      expect((item['when']['en'] as String), contains('6:30 PM'));
      expect(eventTime(tz.TZDateTime(mosqueTz, 2026, 11, 20, 18, 30)), '6:30 PM');
    });
  });

  group('mosque document', () {
    ContentBundle bundle({String phone = '647 834 2000', Object? lat}) => ContentBundle.parse(
          {
            'content': {
              'mosque_info': {
                'name': 'Pape',
                'street': '336 Pape Avenue',
                'city': 'Toronto, ON',
                'postal_code': 'M4M 2W7',
                'phone': phone,
                'email': 'a@b.c',
                'website': 'https://x.y',
                'hours': const [],
                'lat': ?lat,
                if (lat != null) 'lng': -79.3,
              },
              'app_config': {
                'features': {'events': false},
              },
            },
          },
          fallback: ContentBundle.empty,
          source: ContentSource.live,
        );

    test('phone, tel link, address and the events switch', () {
      final doc = buildMosque(bundle());
      expect(doc['version'], 1);
      expect(doc['phone'], '647 834 2000');
      expect(doc['tel'], 'tel:+16478342000');
      expect(doc['address'], '336 Pape Avenue, Toronto, ON M4M 2W7');
      expect(doc['lat'], isNull);
      expect(doc['eventsEnabled'], isFalse);
    });

    test('coordinates when the panel has them', () {
      final doc = buildMosque(bundle(lat: 43.67));
      expect(doc['lat'], 43.67);
      expect(doc['lng'], -79.3);
    });
  });
}
