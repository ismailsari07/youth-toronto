import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/event_schedule.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:timezone/timezone.dart' as tz;

/// A stored event whose first session is at [firstUtc].
YouthEvent event(
  String firstUtc, {
  String recurrence = 'weekly',
  String? prayer,
}) {
  return YouthEvent.fromJson({
    'id': 'e',
    'title': 'Gençlik Buluşması',
    'date_time': firstUtc,
    'category': 'youth',
    'recurrence': recurrence,
    'starts_after_prayer': prayer,
  });
}

/// A moment on the mosque's clock.
tz.TZDateTime toronto(int y, int m, int d, [int h = 12, int min = 0]) =>
    tz.TZDateTime(mosqueTz, y, m, d, h, min);

void main() {
  setUpAll(initMosqueTime);

  // Gençlik Buluşması as stored: Wednesday 30 Sep 2026, 7:30 PM EDT.
  const wednesday = '2026-09-30T23:30:00+00:00';

  group('one-off events', () {
    test('keep their stored start', () {
      final e = event(wednesday, recurrence: 'none');
      final next = nextOccurrence(e, toronto(2026, 10, 20));
      expect(next.toUtc(), DateTime.utc(2026, 9, 30, 23, 30));
    });

    test('are listed through their day, then drop off', () {
      final e = event(wednesday, recurrence: '');
      expect(upcomingEvents([e], toronto(2026, 9, 30, 23, 59)), hasLength(1));
      expect(upcomingEvents([e], toronto(2026, 10, 1, 0, 1)), isEmpty);
    });

    test('unknown recurrence values are treated as one-off', () {
      expect(event(wednesday, recurrence: 'daily').repeats,
          EventRecurrence.none);
    });
  });

  group('weekly', () {
    test('before the first session, the first session is next', () {
      final next = nextOccurrence(event(wednesday), toronto(2026, 9, 25));
      expect(next.toUtc(), DateTime.utc(2026, 9, 30, 23, 30));
    });

    test('rolls forward to the next Wednesday', () {
      final next = nextOccurrence(event(wednesday), toronto(2026, 10, 2));
      expect([next.year, next.month, next.day], [2026, 10, 7]);
      expect(next.weekday, DateTime.wednesday);
      expect([next.hour, next.minute], [19, 30]);
    });

    test("today's session stays listed all day, even after it starts", () {
      final late = toronto(2026, 10, 7, 23, 50);
      final next = nextOccurrence(event(wednesday), late);
      expect([next.month, next.day], [10, 7]);
      expect(upcomingEvents([event(wednesday)], late), hasLength(1));
    });

    test('never disappears, however long ago the first session was', () {
      final next = nextOccurrence(event(wednesday), toronto(2028, 6, 15));
      expect(next.weekday, DateTime.wednesday);
      expect(next.isBefore(toronto(2028, 6, 15, 0)), isFalse);
      expect(next.difference(toronto(2028, 6, 15, 0)).inDays, lessThan(7));
    });

    test('DST ends 1 Nov 2026: still 7:30 PM, one hour later in UTC', () {
      final before = nextOccurrence(event(wednesday), toronto(2026, 10, 28));
      final after = nextOccurrence(event(wednesday), toronto(2026, 11, 2));
      expect([after.month, after.day], [11, 4]);
      expect([before.hour, before.minute], [19, 30]);
      expect([after.hour, after.minute], [19, 30]);
      expect(before.toUtc(), DateTime.utc(2026, 10, 28, 23, 30)); // EDT
      expect(after.toUtc(), DateTime.utc(2026, 11, 5, 0, 30)); // EST
    });

    test('DST starts 14 Mar 2027: still 7:30 PM, one hour earlier in UTC', () {
      final before = nextOccurrence(event(wednesday), toronto(2027, 3, 9));
      final after = nextOccurrence(event(wednesday), toronto(2027, 3, 15));
      expect([before.month, before.day], [3, 10]);
      expect([after.month, after.day], [3, 17]);
      expect([after.hour, after.minute], [19, 30]);
      expect(before.toUtc(), DateTime.utc(2027, 3, 11, 0, 30)); // EST
      expect(after.toUtc(), DateTime.utc(2027, 3, 17, 23, 30)); // EDT
    });
  });

  group('biweekly', () {
    test('keeps its own fortnight, not the next Wednesday', () {
      final e = event(wednesday, recurrence: 'biweekly');
      // 7 Oct is an off week; the next session is 14 Oct.
      final next = nextOccurrence(e, toronto(2026, 10, 2));
      expect([next.month, next.day], [10, 14]);
      final onTheDay = nextOccurrence(e, toronto(2026, 10, 14, 21));
      expect([onTheDay.month, onTheDay.day], [10, 14]);
    });
  });

  group('monthly', () {
    test('same day of the month, same time', () {
      final e = event('2026-09-15T23:30:00+00:00', recurrence: 'monthly');
      final next = nextOccurrence(e, toronto(2026, 11, 20));
      expect([next.year, next.month, next.day], [2026, 12, 15]);
      expect([next.hour, next.minute], [19, 30]);
    });

    test('the 31st clamps to short months without drifting', () {
      final e = event('2027-01-31T23:30:00+00:00', recurrence: 'monthly');
      final feb = nextOccurrence(e, toronto(2027, 2, 2));
      final mar = nextOccurrence(e, toronto(2027, 3, 1));
      final apr = nextOccurrence(e, toronto(2027, 4, 2));
      expect([feb.month, feb.day], [2, 28]);
      expect([mar.month, mar.day], [3, 31]);
      expect([apr.month, apr.day], [4, 30]);
    });

    test('rolls into the next year', () {
      final e = event('2026-09-15T23:30:00+00:00', recurrence: 'monthly');
      final next = nextOccurrence(e, toronto(2026, 12, 20));
      expect([next.year, next.month, next.day], [2027, 1, 15]);
    });
  });

  group('upcoming list', () {
    test('recurring events always listed; sorted by next session', () {
      final monday = event('2026-09-28T23:30:00+00:00');
      final friday = event('2026-10-02T23:30:00+00:00');
      final list =
          upcomingEvents([friday, event(wednesday), monday], toronto(2026, 12, 1));
      expect(list.map((u) => u.startsAt.weekday), [
        DateTime.wednesday,
        DateTime.friday,
        DateTime.monday,
      ]);
    });
  });

  group('prayer-linked estimate', () {
    PrayerCachePayload cacheFor(String ddMMyyyy, {String? iqamah = '7:07'}) {
      return PrayerCachePayload(
        gregorianDate: ddMMyyyy,
        hijriDate: '',
        dailyPrayerTimes: [
          const DailyPrayerItem(name: 'Isha', time: '8:24', iqamah: '8:35'),
          DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: iqamah),
        ],
      );
    }

    final friday = DateTime(2026, 10, 2);

    test('iqamah + 10 minutes, rounded up to 5 (7:07 → 7:20 PM)', () {
      final t = prayerLinkedEstimate(
        prayerKey: 'maghrib',
        day: friday,
        cache: cacheFor('02.10.2026'),
      )!;
      expect([t.hour, t.minute], [19, 20]);
    });

    test('an exact multiple of 5 is kept (7:05 → 7:15 PM)', () {
      final t = prayerLinkedEstimate(
        prayerKey: 'maghrib',
        day: friday,
        cache: cacheFor('02.10.2026', iqamah: '7:05'),
      )!;
      expect([t.hour, t.minute], [19, 15]);
    });

    test('falls back to the athan when no iqamah is listed', () {
      final t = prayerLinkedEstimate(
        prayerKey: 'maghrib',
        day: friday,
        cache: cacheFor('02.10.2026', iqamah: null),
      )!;
      expect([t.hour, t.minute], [19, 15]); // 7:02 + 10 = 7:12 → 7:15
    });

    test('no estimate unless the cache is for that very day', () {
      expect(
        prayerLinkedEstimate(
          prayerKey: 'maghrib',
          day: friday,
          cache: cacheFor('25.09.2026'),
        ),
        isNull,
      );
      expect(
        prayerLinkedEstimate(prayerKey: 'maghrib', day: friday, cache: null),
        isNull,
      );
    });

    test('the prayer key is read from the row and validated', () {
      expect(event(wednesday, prayer: 'Maghrib').startsAfterPrayer, 'maghrib');
      expect(event(wednesday, prayer: 'sunrise').startsAfterPrayer, isNull);
      expect(event(wednesday).startsAfterPrayer, isNull);
    });
  });
}
