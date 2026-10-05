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
/// on a 12-hour clock with no AM/PM.
PrayerCachePayload _payload({String? dhuhrIqamah = '1:45'}) =>
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
      gregorianDate: '04.10.2026',
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
    days = [(date: '2026-10-04', payload: _payload())];
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

    test('7 days, at most 35, all in Toronto time and in the future', () {
      final all = build(const ReminderSettings());
      expect(all, hasLength(35));
      expect(all.every((r) => r.at.location == mosqueTz), isTrue);
      expect(all.every((r) => r.at.isAfter(now)), isTrue);
      expect(all.map((r) => r.id).toSet(), hasLength(35));
      expect(build(atAthan), hasLength(35));
    });

    test('only the chosen prayers', () {
      final some = build(const ReminderSettings(prayers: {'Fajr', 'Isha'}));
      expect(some.map((r) => r.title).toSet(), {'Fajr', 'Isha'});
      expect(some, hasLength(14));
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
      SharedPreferences.setMockInitialValues({});
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
