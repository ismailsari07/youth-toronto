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
  }) =>
      buildReminders(days, settings, l ?? en, now: now, sound: sound);

  const atAthan = ReminderSettings(timing: ReminderTiming.atAthan);

  group('schedule', () {
    test('defaults: all five prayers, 5 minutes before the iqamah', () {
      final today = build(const ReminderSettings()).take(5).toList();
      expect(today.map((r) => r.title), ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
      // Stored 12-hour times read as 24-hour: Dhuhr 1:45 → 13:45.
      expect(
        today.map((r) => '${r.at.hour}:${r.at.minute}'),
        ['6:40', '13:40', '16:40', '18:57', '20:25'],
      );
      expect(today.every((r) => r.sound == ReminderSound.standard), isTrue);
    });

    test('at athan time uses the athan times and the chosen sound', () {
      final today = build(atAthan, sound: ReminderSound.silent).take(5);
      expect(
        today.map((r) => '${r.at.hour}:${r.at.minute}'),
        ['5:43', '13:11', '16:23', '19:2', '20:19'],
      );
      expect(today.every((r) => r.sound == ReminderSound.silent), isTrue);
    });

    test('5 days (Sun 4 – Thu 8 Oct), at most 25, Toronto time, all ahead', () {
      expect(reminderDays, 5);
      final all = build(const ReminderSettings());
      expect(all, hasLength(25));
      expect(all.map((r) => r.at.day).toSet(), {4, 5, 6, 7, 8});
      expect(all.every((r) => r.at.location == mosqueTz), isTrue);
      expect(all.every((r) => r.at.isAfter(now)), isTrue);
      expect(all.map((r) => r.id).toSet(), hasLength(25));
      expect(build(atAthan), hasLength(25));
    });

    test('only the chosen prayers', () {
      final some = build(const ReminderSettings(prayers: {'Fajr', 'Isha'}));
      expect(some.map((r) => r.title).toSet(), {'Fajr', 'Isha'});
      expect(some, hasLength(10));
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

    test('no iqamah: skipped before the iqamah, kept at athan time', () {
      days = [(date: '2026-10-04', payload: _payload(dhuhrIqamah: null))];
      expect(
        build(const ReminderSettings()).take(4).map((r) => r.title),
        isNot(contains('Dhuhr')),
      );
      final dhuhr = build(atAthan).firstWhere((r) => r.title == 'Dhuhr');
      expect(dhuhr.body, "It's time for Dhuhr prayer");
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
      expect(build(atAthan), isEmpty);
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

  group('Friday: Jumu\'ah instead of Dhuhr', () {
    Reminder friday(ReminderSettings s, {AppLocalizations? l}) => build(s, l: l)
        .singleWhere((r) => r.at.weekday == DateTime.friday && r.id % 10 == 1);

    setUp(() {
      // Wednesday 28 October 2026, 3:00; Friday 30 October is in range.
      now = tz.TZDateTime(mosqueTz, 2026, 10, 28, 3);
      days = _rows(DateTime(2026, 10, 28), 10);
    });

    test("at athan time: at the row's jumaaPrayerTime, not Dhuhr's athan", () {
      final r = friday(atAthan);
      expect((r.at.hour, r.at.minute), (14, 0));
      expect(r.title, "Jumu'ah");
      expect(r.body, "It's time for Jumu'ah prayer");
      expect(r.id, 21);
    });

    test('5 minutes before: 5 minutes before the Jumu\'ah time', () {
      final r = friday(const ReminderSettings());
      expect((r.at.hour, r.at.minute), (13, 55));
      expect(r.body, "Jumu'ah in 5 minutes");
      expect(r.sound, ReminderSound.standard);
    });

    test('Turkish and French', () {
      expect(friday(atAthan, l: tr).title, 'Cuma namazı');
      expect(friday(atAthan, l: tr).body, 'Cuma namazı vakti');
      expect(friday(const ReminderSettings(), l: tr).body, 'Cuma namazına 5 dakika kaldı');
      expect(friday(atAthan, l: fr).title, 'Prière du vendredi');
      expect(friday(atAthan, l: fr).body, "C'est l'heure de la prière du vendredi");
      expect(friday(const ReminderSettings(), l: fr).body, 'Prière du vendredi dans 5 minutes');
    });

    test('across the DST change: Fri 30 Oct 2:00 PM EDT, Fri 6 Nov 1:00 PM EST', () {
      expect(friday(atAthan).at.toUtc(), DateTime.utc(2026, 10, 30, 18));
      now = tz.TZDateTime(mosqueTz, 2026, 11, 4, 3);
      days = [
        ..._rows(DateTime(2026, 11, 4), 2),
        _row(DateTime(2026, 11, 6), jumuah: '1:00'),
        ..._rows(DateTime(2026, 11, 7), 2),
      ];
      final r = friday(atAthan);
      expect((r.at.hour, r.at.minute), (13, 0));
      expect(r.at.timeZoneOffset, const Duration(hours: -5));
      expect(r.at.toUtc(), DateTime.utc(2026, 11, 6, 18));
    });

    test('a Friday without a Jumu\'ah time: no Dhuhr reminder, never Dhuhr\'s time', () {
      days = [
        ..._rows(DateTime(2026, 10, 28), 2),
        _row(DateTime(2026, 10, 30), jumuah: null),
        ..._rows(DateTime(2026, 10, 31), 2),
      ];
      final all = build(atAthan);
      expect(all.where((r) => r.at.day == 30).map((r) => r.title), ['Fajr', 'Asr', 'Maghrib', 'Isha']);
      days = [_row(DateTime(2026, 10, 30), jumuah: 'soon')];
      expect(build(atAthan).map((r) => r.title), isNot(contains("Jumu'ah")));
    });

    test('follows the Dhuhr switch', () {
      final noDhuhr = build(const ReminderSettings(prayers: {'Fajr', 'Asr', 'Maghrib', 'Isha'}));
      expect(noDhuhr.map((r) => r.title), isNot(contains("Jumu'ah")));
    });

    test('other days keep Dhuhr', () {
      final thursday = build(atAthan).firstWhere((r) => r.at.day == 29 && r.id % 10 == 1);
      expect(thursday.title, 'Dhuhr');
      expect((thursday.at.hour, thursday.at.minute), (13, 11));
    });
  });

  group('notification text names the prayer', () {
    Reminder dhuhr(ReminderSettings s, AppLocalizations l) =>
        build(s, l: l).firstWhere((r) => r.id == 1);
    Reminder fajr(ReminderSettings s, AppLocalizations l) =>
        build(s, l: l).firstWhere((r) => r.id == 0);

    test('English', () {
      expect(dhuhr(atAthan, en).title, 'Dhuhr');
      expect(dhuhr(atAthan, en).body,
          "It's time for Dhuhr prayer · Iqamah at 1:45 PM");
      expect(dhuhr(const ReminderSettings(), en).body,
          'Dhuhr iqamah in 5 minutes');
      expect(fajr(atAthan, en).body,
          "It's time for Fajr prayer · Iqamah at 6:45 AM");
      expect(fajr(const ReminderSettings(), en).body,
          'Fajr iqamah in 5 minutes');
    });

    test('French', () {
      expect(dhuhr(atAthan, fr).title, 'Dhohr');
      expect(dhuhr(atAthan, fr).body,
          "C'est l'heure de la prière du Dhohr · Iqama à 1:45 PM");
      expect(dhuhr(const ReminderSettings(), fr).body,
          'Iqama du Dhohr dans 5 minutes');
      final asr = build(const ReminderSettings(), l: fr)
          .firstWhere((r) => r.id == 2);
      expect(asr.body, "Iqama de l'Asr dans 5 minutes");
    });

    test('Turkish: İmsak as the title, Sabah namazı in the body', () {
      expect(dhuhr(atAthan, tr).title, 'Öğle');
      expect(dhuhr(atAthan, tr).body, 'Öğle namazı vakti girdi · Cemaat 1:45 PM');
      expect(dhuhr(const ReminderSettings(), tr).body,
          'Öğle cemaatine 5 dakika kaldı');
      expect(fajr(atAthan, tr).title, 'İmsak');
      expect(fajr(atAthan, tr).body, 'Sabah namazı vakti girdi · Cemaat 6:45 AM');
      expect(fajr(const ReminderSettings(), tr).body,
          'Sabah namazı cemaatine 5 dakika kaldı');
    });
  });

  group('settings', () {
    test('a device from before these options keeps what it had', () async {
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': true});
      final s = await ReminderSync.loadSettings();
      expect(s.enabled, isTrue);
      expect(s.prayers, ReminderSettings.allPrayers);
      expect(s.timing, ReminderTiming.beforeIqamah);
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
        timing: ReminderTiming.atAthan,
        sound: ReminderSound.silent,
      ));
      final s = await ReminderSync.loadSettings();
      expect(s.prayers, {'Asr'});
      expect(s.timing, ReminderTiming.atAthan);
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
