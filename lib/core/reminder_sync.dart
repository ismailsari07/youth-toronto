import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n.dart';
import '../shared/formatters.dart';
import 'mosque_time.dart';
import 'notification_service.dart';
import 'notification_sounds.dart';
import 'prayer_days.dart';
import 'prayer_service.dart';
import 'reminder_settings.dart';

/// Keeps this device's prayer notifications in step with the mosque
/// schedule and the member's choices: the chosen prayers, at athan time or
/// 5 minutes before the iqamah, 7 days ahead, in Toronto time.
///
/// The settings live on the device (notifications are per device), so they
/// work signed in or out. The server's notifications_enabled is not read.
class ReminderSync {
  static const _enabledKey = 'prayer_reminders_enabled';
  static const _prayersKey = 'prayer_reminders_prayers';
  static const _timingKey = 'prayer_reminders_timing';
  static const _soundKey = 'prayer_reminders_sound';

  static Future<void>? _inFlight;
  static bool _rerun = false;

  /// Keys written before a setting existed read as its default, so
  /// existing members keep the original behaviour (see [ReminderSettings]).
  static Future<ReminderSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prayers = prefs.getStringList(_prayersKey);
      return ReminderSettings(
        enabled: prefs.getBool(_enabledKey) ?? true,
        prayers: prayers == null
            ? ReminderSettings.allPrayers
            : prayers.where(ReminderSettings.allPrayers.contains).toSet(),
        timing: ReminderTiming.values.asNameMap()[prefs.getString(_timingKey)] ??
            ReminderTiming.beforeIqamah,
        sound: ReminderSound.values.asNameMap()[prefs.getString(_soundKey)],
      );
    } catch (e) {
      debugPrint('ReminderSync: reading settings failed: $e');
      return const ReminderSettings();
    }
  }

  static Future<void> saveSettings(ReminderSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, s.enabled);
    await prefs.setStringList(_prayersKey, s.prayers.toList());
    await prefs.setString(_timingKey, s.timing.name);
    final sound = s.sound;
    if (sound != null) await prefs.setString(_soundKey, sound.name);
  }

  /// Safe to call any time; never throws. Only one run at a time: a call made
  /// during a run (e.g. a switch flipped mid-sync) queues one fresh run
  /// afterwards, so the latest settings and data always win.
  static Future<void> sync() {
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    return _inFlight = _loop();
  }

  static Future<void> _loop() async {
    try {
      do {
        _rerun = false;
        await _run();
      } while (_rerun);
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _run() async {
    try {
      final settings = await loadSettings();
      if (!settings.active) {
        await NotificationService.cancelAll();
        return;
      }
      await NotificationService.requestPermissions();

      final List<PrayerDay> days;
      try {
        days = await PrayerService.fetchRecentDays();
      } catch (e) {
        // Offline or server error: keep the notifications already scheduled.
        debugPrint('ReminderSync: loading prayer days failed: $e');
        return;
      }
      if (days.isEmpty) return;

      // Notification text is fixed when scheduled, so it is written in the
      // language the app shows now; changing language re-runs this sync.
      final l = await currentAppLocalizations();
      final sound = settings.soundWith(
        athanBundled: await NotificationSounds.athanBundled(),
      );
      await NotificationService.scheduleReminders(
        buildReminders(days, settings, l, now: mosqueNow(), sound: sound),
        channelName: l.prayerReminders,
      );
    } catch (e) {
      debugPrint('ReminderSync: sync failed: $e');
    }
  }
}

const _prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _daysAhead = 7; // 7 × 5 prayers = 35, under iOS's 64 cap
const _leadTime = Duration(minutes: 5);

/// Every notification [settings] asks for over the next 7 mosque-calendar
/// days from [now], in time order. At athan time they use [sound]; 5
/// minutes before the iqamah, always the standard sound.
///
/// No row yet for future days (prayer_cache only holds up to today):
/// scheduleDays uses the latest known day's times, refreshed on every
/// open/resume.
List<Reminder> buildReminders(
  List<PrayerDay> days,
  ReminderSettings settings,
  AppLocalizations l, {
  required tz.TZDateTime now,
  required ReminderSound sound,
}) {
  if (!settings.active) return const [];
  final atAthan = settings.timing == ReminderTiming.atAthan;
  final reminders = <Reminder>[];

  for (final (offset: i, :day, :payload)
      in scheduleDays(days, now, count: _daysAhead)) {
    for (final item in payload.dailyPrayerTimes) {
      final index = _prayerOrder.indexOf(item.name);
      if (index < 0 || !settings.prayers.contains(item.name)) continue;
      final key = item.name.toLowerCase();
      final iqamah = item.iqamah;
      final iqamahKnown =
          iqamah != null && prayerClock(item.name, iqamah) != null;

      final tz.TZDateTime? at;
      final String body;
      if (atAthan) {
        at = prayerMoment(day, item.name, item.time);
        body = iqamahKnown
            ? '${l.reminderAthanBody(key)} · '
                '${l.reminderIqamahAt(prayerClock12(item.name, iqamah))}'
            : l.reminderAthanBody(key);
      } else {
        if (!iqamahKnown) continue;
        at = prayerMoment(day, item.name, iqamah)?.subtract(_leadTime);
        body = l.reminderIqamahSoon(key);
      }
      if (at == null || !at.isAfter(now)) continue;

      reminders.add((
        id: i * 10 + index,
        title: l.prayer(key),
        body: body,
        at: at,
        sound: atAthan ? sound : ReminderSound.standard,
      ));
    }
  }
  return reminders;
}
