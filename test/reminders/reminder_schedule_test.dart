import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/notification_service.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/reminder_settings.dart';
import 'package:myt_flutter/core/reminder_sync.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/reminders_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// One prayer_cache row as pape-api stores it: afternoon and evening times
/// on a 12-hour clock with no AM/PM. [date] is its Diyanet date
/// (DD.MM.YYYY), which must be the row's own.
PrayerCachePayload _payload({
  String? dhuhrIqamah = '1:45',
  String date = '04.10.2026',
  String? jumuah = '2:00',
}) =>
    PrayerCachePayload(
      dailyPrayerTimes: [
        const DailyPrayerItem(name: 'Fajr', time: '5:43', iqamah: '6:45'),
        const DailyPrayerItem(name: 'Sunrise', time: '7:11'),
        DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: dhuhrIqamah),
        const DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
        const DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
        const DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
      ],
      hijriDate: '23.4.1448',
      gregorianDate: date,
      jumaaPrayerTime: jumuah,
    );

/// Real rows for [count] days from [from], each with its own date.
List<PrayerDay> _rows(DateTime from, int count, {String? jumuah = '2:00'}) => [
      for (var i = 0; i < count; i++)
        _row(DateTime(from.year, from.month, from.day + i), jumuah: jumuah),
    ];

PrayerDay _row(DateTime day, {String? jumuah = '2:00', String? diyanetDay}) => (
      date: mosqueDateKey(day),
      payload: _payload(date: diyanetDay ?? diyanetDate(day), jumuah: jumuah),
    );

void main() {
  setUpAll(initMosqueTime);

  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final tr = lookupAppLocalizations(const Locale('tr'));

  // Sunday 4 October 2026, 3:00 AM in Toronto: before every prayer today.
  late tz.TZDateTime now;
  late List<PrayerDay> days;

  setUp(() {
    now = tz.TZDateTime(mosqueTz, 2026, 10, 4, 3);
    // The 30-day window: far more rows than the horizon.
    days = _rows(DateTime(2026, 10, 4), 30);
  });

  List<Reminder> build(
    ReminderSettings settings, {
    AppLocalizations? l,
    ReminderSound sound = ReminderSound.standard,
    int budget = reminderBudget,
  }) =>
      buildReminders(days, settings, l ?? en,
          now: now, sound: sound, budget: budget);

  group('schedule', () {
    test('defaults: all five prayers, each at its athan, in the chosen sound', () {
      final today = build(const ReminderSettings(), sound: ReminderSound.silent).take(5).toList();
      expect(today.map((r) => r.title), ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
      // Stored 12-hour times read as 24-hour: Dhuhr 1:11 → 13:11.
      expect(
        today.map((r) => '${r.at.hour}:${r.at.minute}'),
        ['5:43', '13:11', '16:23', '19:2', '20:19'],
      );
      expect(today.every((r) => r.sound == ReminderSound.silent), isTrue);
    });

    test('Toronto time, all ahead, unique ids', () {
      final all = build(const ReminderSettings());
      expect(all.every((r) => r.at.location == mosqueTz), isTrue);
      expect(all.every((r) => r.at.isAfter(now)), isTrue);
      expect(all.map((r) => r.id).toSet(), hasLength(all.length));
    });
    test('only the chosen prayers', () {
      final some = build(const ReminderSettings(prayers: {'Fajr', 'Isha'}));
      expect(some.map((r) => r.title).toSet(), {'Fajr', 'Isha'});
      expect(some.where((r) => r.at.day == 4), hasLength(2));
    });

    test('nothing when the master switch is off or no prayer is chosen', () {
      expect(build(const ReminderSettings(enabled: false)), isEmpty);
      expect(build(const ReminderSettings(prayers: {})), isEmpty);
    });

    test('times already past today are skipped', () {
      now = tz.TZDateTime(mosqueTz, 2026, 10, 4, 14); // after Dhuhr
      final first = build(const ReminderSettings()).first;
      expect(first.title, 'Asr');
      expect(first.at.day, 4);
    });

    test('no iqamah: still fires at the athan, without an iqamah time', () {
      days = [(date: '2026-10-04', payload: _payload(dhuhrIqamah: null))];
      final dhuhr = build(const ReminderSettings()).firstWhere((r) => r.title == 'Dhuhr');
      expect((dhuhr.at.hour, dhuhr.at.minute), (13, 11));
      expect(dhuhr.body, "It's time for Dhuhr prayer");
    });

    test('an athan that cannot be read gets no reminder, never a guess', () {
      days = [
        (
          date: '2026-10-04',
          payload: PrayerCachePayload(
            dailyPrayerTimes: const [
              DailyPrayerItem(name: 'Dhuhr', time: 'soon', iqamah: '1:45'),
              DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
            ],
            hijriDate: '',
            gregorianDate: '04.10.2026',
          ),
        ),
      ];
      expect(build(const ReminderSettings()).map((r) => r.title), ['Asr']);
    });
  });

  group('budget: whole days into 63 of iOS\'s 64 slots', () {
    Set<int> daysOf(List<Reminder> r) => r.map((x) => x.at.day).toSet();
    Set<int> range(int from, int to) => {for (var d = from; d <= to; d++) d};

    test('63 for reminders, 1 for the notice, nothing else local', () {
      expect(iosPendingLimit, 64);
      expect(otherLocalNotifications, 0);
      expect(reminderBudget, 63);
      expect(reminderBudget + noticeSlots + otherLocalNotifications, 64);
    });

    test('all five prayers: 12 days (Sun 4 – Thu 15 Oct), 60 reminders', () {
      final all = build(const ReminderSettings());
      expect(all, hasLength(60));
      expect(daysOf(all), range(4, 15));
    });

    test('three prayers: 21 days, exactly 63', () {
      final all = build(const ReminderSettings(prayers: {'Fajr', 'Asr', 'Isha'}));
      expect(all, hasLength(63));
      expect(daysOf(all), range(4, 24));
    });

    test('one prayer: 63 days when the rows reach that far', () {
      days = _rows(DateTime(2026, 10, 4), 70);
      final all = build(const ReminderSettings(prayers: {'Asr'}));
      expect(all, hasLength(63));
      expect(all.last.at.month, 12);
      expect(all.last.at.day, 5); // 4 Oct + 62 days
    });

    test('a partly past today still counts whole days: 3 + 12 × 5 = 63', () {
      now = tz.TZDateTime(mosqueTz, 2026, 10, 4, 14); // after Dhuhr
      final all = build(const ReminderSettings());
      expect(all.where((r) => r.at.day == 4).map((r) => r.title),
          ['Asr', 'Maghrib', 'Isha']);
      expect(all, hasLength(63));
      expect(daysOf(all), range(4, 16));
    });

    test('never half a day: the first day that does not fit ends it', () {
      final all = build(const ReminderSettings(), budget: 13);
      expect(all, hasLength(10));
      expect(daysOf(all), {4, 5});
    });

    test("Friday costs the same five slots, Jumu'ah time or not", () {
      final friday = build(const ReminderSettings()).where((r) => r.at.day == 9);
      expect(friday.map((r) => r.title), ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
      days = _rows(DateTime(2026, 10, 4), 30, jumuah: null);
      expect(build(const ReminderSettings()), hasLength(60));
    });

    test('the rows run out before the budget: they stop there, nothing filled', () {
      days = [
        ..._rows(DateTime(2026, 10, 4), 3),
        _row(DateTime(2026, 10, 8)), // 7 Oct missing
      ];
      final all = build(const ReminderSettings());
      expect(all, hasLength(20));
      expect(daysOf(all), {4, 5, 6, 8});
      final one = build(const ReminderSettings(prayers: {'Isha'}));
      expect(daysOf(one), {4, 5, 6, 8});
    });
  });

  group('the "open the app" notice', () {
    Reminder? notice(ReminderSettings s, {AppLocalizations? l}) {
      final loc = l ?? en;
      final reminders =
          buildReminders(days, s, loc, now: now, sound: ReminderSound.standard);
      return buildNotice(days, reminders, loc, now: now, sound: ReminderSound.standard);
    }

    String hm(tz.TZDateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    test('10:00 Toronto time on the last scheduled day', () {
      final n = notice(const ReminderSettings())!;
      expect((n.at.month, n.at.day), (10, 15));
      expect(hm(n.at), '10:00');
      expect(n.at.location, mosqueTz);
      expect(n.id, noticeId);
      expect(n.title, 'Prayer reminders');
      expect(n.body,
          'Your prayer reminders will stop tomorrow. Open Pape Mosque once to keep them coming at the right times.');
      // Its id is clear of every reminder's.
      final ids = build(const ReminderSettings(prayers: {'Asr'})).map((r) => r.id);
      expect(ids, isNot(contains(noticeId)));
    });

    test('Turkish and French', () {
      expect(notice(const ReminderSettings(), l: tr)!.body,
          "Namaz hatırlatmalarınız yarın duracak. Doğru saatte gelmeye devam etmeleri için Pape Mosque'u bir kez açmanız yeterli.");
      expect(notice(const ReminderSettings(), l: fr)!.body,
          "Vos rappels de prière s'arrêteront demain. Ouvrez Pape Mosque une fois pour continuer à les recevoir à l'heure.");
    });

    test('follows the last scheduled day when the rows run out', () {
      days = _rows(DateTime(2026, 10, 4), 2);
      final n = notice(const ReminderSettings())!;
      expect((n.at.day, hm(n.at)), (5, '10:00'));
    });

    test('silent only when the member chose silent', () {
      final reminders = build(const ReminderSettings());
      for (final (chosen, used) in [
        (ReminderSound.silent, ReminderSound.silent),
        (ReminderSound.athan, ReminderSound.standard),
        (ReminderSound.standard, ReminderSound.standard),
      ]) {
        expect(buildNotice(days, reminders, en, now: now, sound: chosen)!.sound, used);
      }
    });

    group('10:00 already passed on the last day (today)', () {
      setUp(() => days = [_row(DateTime(2026, 10, 4))]);
      tz.TZDateTime at(int h, int m) => tz.TZDateTime(mosqueTz, 2026, 10, 4, h, m);

      test('the middle of the next prayer gap still ahead', () {
        // Dhuhr's iqamah 13:45 → Asr 16:23.
        now = at(11, 0);
        expect(hm(notice(const ReminderSettings())!.at), '15:04');
        // Asr's iqamah 16:45 → Maghrib 19:02.
        now = at(15, 30);
        expect(hm(notice(const ReminderSettings())!.at), '17:53');
        // Maghrib 19:02 → Isha 20:19.
        now = at(18, 0);
        expect(hm(notice(const ReminderSettings())!.at), '19:40');
      });

      test('no gap left: no notice', () {
        now = at(19, 45);
        expect(build(const ReminderSettings()), isNotEmpty); // Isha is ahead
        expect(notice(const ReminderSettings()), isNull);
      });

      test('never in quiet hours (21:30–08:00)', () {
        // A summer evening: Maghrib 20:50, Isha 22:30; the gap's middle is
        // 21:40, so nothing fits.
        final summer = PrayerCachePayload(
          dailyPrayerTimes: const [
            DailyPrayerItem(name: 'Fajr', time: '3:50', iqamah: '4:30'),
            DailyPrayerItem(name: 'Dhuhr', time: '1:20', iqamah: '1:45'),
            DailyPrayerItem(name: 'Asr', time: '5:30', iqamah: '5:45'),
            DailyPrayerItem(name: 'Maghrib', time: '8:50', iqamah: '8:50'),
            DailyPrayerItem(name: 'Isha', time: '10:30', iqamah: '10:40'),
          ],
          hijriDate: '',
          gregorianDate: '04.10.2026',
        );
        days = [(date: '2026-10-04', payload: summer)];
        now = at(19, 30);
        expect(notice(const ReminderSettings()), isNull);
        // Earlier the same day, the Asr → Maghrib gap (19:17) is fine.
        now = at(17, 0);
        expect(hm(notice(const ReminderSettings())!.at), '19:17');
      });

      test("Friday: the gaps are around Jumu'ah, not Dhuhr", () {
        days = [_row(DateTime(2026, 10, 9))];
        now = tz.TZDateTime(mosqueTz, 2026, 10, 9, 11);
        // Jumu'ah 14:00 → Asr 16:23 (Dhuhr's would give 15:04).
        expect(hm(notice(const ReminderSettings())!.at), '15:11');
      });
    });

    test('absent when reminders are off or nothing was scheduled', () {
      expect(notice(const ReminderSettings(enabled: false)), isNull);
      expect(notice(const ReminderSettings(prayers: {})), isNull);
      days = [];
      expect(notice(const ReminderSettings()), isNull);
    });
  });

  group('real rows only (owner: never a wrong time)', () {
    Set<int> daysOf(List<Reminder> r) => r.map((x) => x.at.day).toSet();

    test('a day without its own row gets nothing; it is never filled', () {
      days = [
        _row(DateTime(2026, 10, 4)),
        _row(DateTime(2026, 10, 5)),
        _row(DateTime(2026, 10, 7)),
      ];
      expect(daysOf(build(const ReminderSettings())), {4, 5, 7});
    });

    test('when the data runs out, the reminders stop', () {
      days = _rows(DateTime(2026, 10, 4), 2);
      final all = build(const ReminderSettings());
      expect(daysOf(all), {4, 5});
      expect(all, hasLength(10));
    });

    test("yesterday's row never stands in for today", () {
      days = [_row(DateTime(2026, 10, 3))];
      expect(build(const ReminderSettings()), isEmpty);
    });

    test("a row whose Diyanet date isn't its own is skipped", () {
      days = [
        _row(DateTime(2026, 10, 4)),
        // The 2026-10-01 kind of row: another day's data under this date.
        _row(DateTime(2026, 10, 5), diyanetDay: '06.10.2026'),
      ];
      expect(daysOf(build(const ReminderSettings())), {4});
    });

    test('no rows: nothing', () {
      days = [];
      expect(build(const ReminderSettings()), isEmpty);
    });
  });

  group("Friday: the Dhuhr athan, and the text gives Jumu'ah", () {
    // The first Friday ahead (30 Oct).
    Reminder friday({AppLocalizations? l}) => build(const ReminderSettings(), l: l)
        .firstWhere((r) => r.at.weekday == DateTime.friday && r.id % 10 == 1);

    setUp(() {
      // Wednesday 28 October 2026, 3:00; Friday 30 October is in range.
      now = tz.TZDateTime(mosqueTz, 2026, 10, 28, 3);
      days = _rows(DateTime(2026, 10, 28), 10);
    });

    test("fires at Dhuhr's athan, not at the Jumu'ah time", () {
      final r = friday();
      expect((r.at.hour, r.at.minute), (13, 11));
      expect(r.title, 'Dhuhr');
      expect(r.body, "Dhuhr athan · Jumu'ah at 2:00 PM");
      expect(r.id, 21);
    });

    test('the three languages, each with its own clock', () {
      expect(friday(l: tr).title, 'Öğle');
      expect(friday(l: tr).body, "Öğle ezanı · Cuma namazı 14:00'te");
      expect(friday(l: fr).title, 'Dhohr');
      expect(friday(l: fr).body, 'Adhan du Dhohr · Prière du vendredi à 14\u00A0h');
    });

    test("the owner's example: 13:00'te, and the suffix follows what is said", () {
      days = [_row(DateTime(2026, 10, 30), jumuah: '1:00')];
      expect(friday(l: tr).body, "Öğle ezanı · Cuma namazı 13:00'te");
      days = [_row(DateTime(2026, 10, 30), jumuah: '1:30')];
      expect(friday(l: tr).body, "Öğle ezanı · Cuma namazı 13:30'da");
      expect(friday(l: fr).body, 'Adhan du Dhohr · Prière du vendredi à 13\u00A0h\u00A030');
      expect(friday().body, "Dhuhr athan · Jumu'ah at 1:30 PM");
    });

    test("across the clock change: Dhuhr's athan on either side, Jumu'ah in the text", () {
      expect(friday().at.toUtc(), DateTime.utc(2026, 10, 30, 17, 11)); // EDT
      now = tz.TZDateTime(mosqueTz, 2026, 11, 4, 3);
      days = [
        ..._rows(DateTime(2026, 11, 4), 2),
        _row(DateTime(2026, 11, 6), jumuah: '1:00'),
        ..._rows(DateTime(2026, 11, 7), 2),
      ];
      final r = friday();
      expect((r.at.hour, r.at.minute), (13, 11));
      expect(r.at.timeZoneOffset, const Duration(hours: -5));
      expect(r.at.toUtc(), DateTime.utc(2026, 11, 6, 18, 11));
      expect(r.body, "Dhuhr athan · Jumu'ah at 1:00 PM");
    });

    test("no readable Jumu'ah time: the athan still fires, and no time is invented", () {
      for (final jumuah in [null, 'soon']) {
        days = [_row(DateTime(2026, 10, 30), jumuah: jumuah)];
        final r = friday();
        expect((r.at.hour, r.at.minute), (13, 11));
        expect(r.body, "It's time for Dhuhr prayer");
        expect(friday(l: tr).body, 'Öğle namazı vakti girdi');
      }
    });

    test('follows the Dhuhr switch', () {
      final noDhuhr = build(const ReminderSettings(prayers: {'Fajr', 'Asr', 'Maghrib', 'Isha'}));
      expect(noDhuhr.where((r) => r.at.weekday == DateTime.friday).map((r) => r.title),
          contains('Fajr'));
      expect(noDhuhr.map((r) => r.title), isNot(contains('Dhuhr')));
    });

    test('other days keep the iqamah in the text', () {
      final thursday = build(const ReminderSettings()).firstWhere((r) => r.at.day == 29 && r.id % 10 == 1);
      expect(thursday.body, "It's time for Dhuhr prayer · Iqamah at 1:45 PM");
    });
  });

  // Toronto: 14 March 2027 starts daylight time, 1 November 2026 ends it.
  group('every reminder at the athan, on the days the clock changes', () {
    for (final (day, offsetAfter) in [
      (DateTime(2026, 10, 31), -4),
      (DateTime(2026, 11, 1), -5),
      (DateTime(2026, 11, 2), -5),
      (DateTime(2027, 3, 13), -5),
      (DateTime(2027, 3, 14), -4),
      (DateTime(2027, 3, 15), -4),
    ]) {
      test('${mosqueDateKey(day)}: same wall clock, UTC follows the change', () {
        now = tz.TZDateTime(mosqueTz, day.year, day.month, day.day, 0, 30);
        days = [_row(day)];
        final all = build(const ReminderSettings());
        expect(all.map((r) => '${r.at.hour}:${r.at.minute}'),
            ['5:43', '13:11', '16:23', '19:2', '20:19']);
        expect(all.every((r) => r.at.timeZoneOffset == Duration(hours: offsetAfter)), isTrue);
        expect(all[1].at.toUtc().hour, 13 - offsetAfter);
      });
    }
  });

  group('notification text names the prayer', () {
    Reminder dhuhr(AppLocalizations l) =>
        build(const ReminderSettings(), l: l).firstWhere((r) => r.id == 1);
    Reminder fajr(AppLocalizations l) =>
        build(const ReminderSettings(), l: l).firstWhere((r) => r.id == 0);

    test('English', () {
      expect(dhuhr(en).title, 'Dhuhr');
      expect(dhuhr(en).body, "It's time for Dhuhr prayer · Iqamah at 1:45 PM");
      expect(fajr(en).body, "It's time for Fajr prayer · Iqamah at 6:45 AM");
    });

    test('French', () {
      expect(dhuhr(fr).title, 'Dhohr');
      expect(dhuhr(fr).body,
          "C'est l'heure de la prière du Dhohr · Iqama à 13\u00A0h\u00A045");
    });

    test('Turkish: İmsak as the title, Sabah namazı in the body', () {
      expect(dhuhr(tr).title, 'Öğle');
      expect(dhuhr(tr).body, 'Öğle namazı vakti girdi · Cemaat 13:45');
      expect(fajr(tr).title, 'İmsak');
      expect(fajr(tr).body, 'Sabah namazı vakti girdi · Cemaat 06:45');
    });
  });

  group('settings', () {
    test('a device from before these options gets all five prayers', () async {
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': true});
      final s = await ReminderSync.loadSettings();
      expect(s.enabled, isTrue);
      expect(s.prayers, ReminderSettings.allPrayers);
    });

    test('no saved choice: on only if iOS already allows notifications', () async {
      addTearDown(() => ReminderSync.permissionGranted = NotificationService.notificationsAllowed);
      for (final (granted, on) in [(true, true), (false, false), (null, false)]) {
        SharedPreferences.setMockInitialValues({});
        ReminderSync.permissionGranted = () async => granted;
        expect((await ReminderSync.loadSettings()).enabled, on, reason: '$granted');
      }
      // A saved choice wins either way.
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': false});
      ReminderSync.permissionGranted = () async => true;
      expect((await ReminderSync.loadSettings()).enabled, isFalse);
    });

    test('a device that had reminders off keeps them off', () async {
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': false});
      expect((await ReminderSync.loadSettings()).active, isFalse);
    });

    test('saved choices read back', () async {
      SharedPreferences.setMockInitialValues({});
      await ReminderSync.saveSettings(const ReminderSettings(
        prayers: {'Asr'},
        sound: ReminderSound.silent,
      ));
      final s = await ReminderSync.loadSettings();
      expect(s.prayers, {'Asr'});
      expect(s.sound, ReminderSound.silent);
    });

    test('the athan is the default sound only once it is bundled', () {
      const unset = ReminderSettings();
      expect(unset.soundWith(athanBundled: false), ReminderSound.standard);
      expect(unset.soundWith(athanBundled: true), ReminderSound.athan);
      const athan = ReminderSettings(sound: ReminderSound.athan);
      expect(athan.soundWith(athanBundled: false), ReminderSound.standard);
      const silent = ReminderSettings(sound: ReminderSound.silent);
      expect(silent.soundWith(athanBundled: true), ReminderSound.silent);
    });
  });

  group('switches', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('switching off the last prayer turns everything off; '
        'turning it back on brings all five back', () async {
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reminderSettingsProvider.notifier);
      await container.read(reminderSettingsProvider.future);

      for (final p in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib']) {
        await notifier.setPrayer(p, false);
      }
      expect(container.read(reminderSettingsProvider).value!.active, isTrue);
      await notifier.setPrayer('Isha', false);
      expect(container.read(reminderSettingsProvider).value!.enabled, isFalse);

      await notifier.setEnabled(true);
      expect(
        container.read(reminderSettingsProvider).value!.prayers,
        ReminderSettings.allPrayers,
      );
      expect((await ReminderSync.loadSettings()).active, isTrue);
    });
  });
}
