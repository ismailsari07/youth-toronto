import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n.dart';
import '../shared/formatters.dart';
import 'feature_flags.dart';
import 'models.dart';
import 'mosque_time.dart';
import 'notification_service.dart';
import 'notification_sounds.dart';
import 'prayer_days.dart';
import 'prayer_service.dart';
import 'reminder_settings.dart';

/// Keeps this device's prayer notifications in step with the mosque
/// schedule and the member's choices: the chosen prayers, at athan time or
/// 5 minutes before the iqamah, [reminderDays] days ahead, in Toronto time,
/// only from real prayer_cache rows (see [scheduleDays]).
///
/// Runs on launch, on resume, on pull-to-refresh, on a settings or language
/// change and on a `prayer_refresh` silent push (see
/// prayer_refresh_background.dart). The settings live on the device
/// (notifications are per device), so they work signed in or out.
class ReminderSync {
  static const _enabledKey = 'prayer_reminders_enabled';
  static const _prayersKey = 'prayer_reminders_prayers';
  static const _timingKey = 'prayer_reminders_timing';
  static const _soundKey = 'prayer_reminders_sound';

  static Future<void>? _inFlight;
  static bool _rerun = false;
  static bool _askQueued = false;

  /// Whether iOS lets the app show notifications (null: can't tell). Never
  /// prompts. Replaced in tests.
  @visibleForTesting
  static Future<bool?> Function() permissionGranted =
      NotificationService.notificationsAllowed;

  /// Shows the iOS prompt the first time, then returns the stored answer.
  /// Replaced in tests.
  @visibleForTesting
  static Future<bool> Function() askPermission = NotificationService.requestPermissions;

  /// The rows, and the plugin call that replaces every pending reminder.
  /// Replaced in tests.
  @visibleForTesting
  static Future<List<PrayerDay>> Function({required int first, required int last})
      fetchDays = PrayerService.fetchDays;
  @visibleForTesting
  static Future<void> Function(List<Reminder>, {required String channelName})
      schedule = NotificationService.scheduleReminders;

  /// A saved choice always wins. With none (a new install, or one that
  /// never touched the settings), reminders are on only if iOS already
  /// allows notifications, e.g. after the push pre-prompt; otherwise off.
  /// Other missing keys read as their defaults (see [ReminderSettings]).
  static Future<ReminderSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prayers = prefs.getStringList(_prayersKey);
      return ReminderSettings(
        enabled: prefs.getBool(_enabledKey) ?? await permissionGranted() == true,
        prayers: prayers == null
            ? ReminderSettings.allPrayers
            : prayers.where(ReminderSettings.allPrayers.contains).toSet(),
        timing: ReminderTiming.values.asNameMap()[prefs.getString(_timingKey)] ??
            ReminderTiming.beforeIqamah,
        sound: ReminderSound.values.asNameMap()[prefs.getString(_soundKey)],
      );
    } catch (e) {
      debugPrint('ReminderSync: reading settings failed: $e');
      return const ReminderSettings(enabled: false);
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
  ///
  /// [ask]: the member just turned reminders on, so iOS may show its
  /// permission prompt. Every other caller (launch, resume, refresh, push)
  /// leaves it false: the prompt never appears on its own.
  static Future<void> sync({bool ask = false}) {
    _askQueued |= ask;
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
        final ask = _askQueued;
        _askQueued = false;
        await _run(ask: ask);
      } while (_rerun);
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _run({required bool ask}) async {
    try {
      if (!kPrayerRemindersEnabled) {
        // Switched off: cancel anything an earlier build scheduled, and
        // never ask for permission.
        await NotificationService.cancelPending();
        return;
      }
      final settings = await loadSettings();
      if (!settings.active) {
        await NotificationService.cancelAll();
        return;
      }
      final allowed = ask ? await askPermission() : await permissionGranted();
      // Not allowed: nothing would show. The sheet explains it.
      if (allowed == false) return;

      final List<PrayerDay> days;
      try {
        days = await fetchDays(first: 0, last: reminderDays - 1);
      } catch (e) {
        // Offline or server error: keep the notifications already
        // scheduled. They came from real rows.
        debugPrint('ReminderSync: loading prayer days failed: $e');
        return;
      }

      // Notification text is fixed when scheduled, so it is written in the
      // language the app shows now; changing language re-runs this sync.
      final l = await currentAppLocalizations();
      final sound = settings.soundWith(
        athanBundled: await NotificationSounds.athanBundled(),
      );
      // No rows at all is real too: everything pending is cleared.
      await schedule(
        buildReminders(days, settings, l, now: mosqueNow(), sound: sound),
        channelName: l.prayerReminders,
      );
    } catch (e) {
      debugPrint('ReminderSync: sync failed: $e');
    }
  }
}

const _prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _leadTime = Duration(minutes: 5);

/// How many mosque-calendar days are scheduled, today included: at most
/// 5 × 5 = 25 pending, well under iOS's 64. Short on purpose: a correction
/// the app hasn't heard about (no silent push, app not opened) can only
/// stay wrong this long, and a phone that never syncs stops after it.
const reminderDays = 5;

/// Every notification [settings] asks for over the next [reminderDays]
/// mosque-calendar days from [now], in time order, from real rows only (a
/// day without its own row gets nothing). At athan time they use [sound];
/// 5 minutes before the iqamah, always the standard sound.
///
/// Friday's Dhuhr is Jumu'ah: "Cuma namazı" at that row's
/// `jumaaPrayerTime`, used as both the athan and the iqamah time. A Friday
/// without a readable Jumu'ah time gets no Dhuhr reminder (never Dhuhr's).
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
      in scheduleDays(days, now, count: reminderDays)) {
    for (final item in payload.dailyPrayerTimes) {
      final index = _prayerOrder.indexOf(item.name);
      if (index < 0 || !settings.prayers.contains(item.name)) continue;
      if (item.name == 'Dhuhr' && day.weekday == DateTime.friday) {
        final jumuah = _jumuah(i, index, day, payload, l,
            now: now, atAthan: atAthan, sound: sound);
        if (jumuah != null) reminders.add(jumuah);
        continue;
      }
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

Reminder? _jumuah(
  int offset,
  int index,
  DateTime day,
  PrayerCachePayload payload,
  AppLocalizations l, {
  required tz.TZDateTime now,
  required bool atAthan,
  required ReminderSound sound,
}) {
  final time = payload.jumaaPrayerTime;
  final moment = time == null ? null : prayerMoment(day, 'Dhuhr', time);
  if (moment == null) return null;
  final at = atAthan ? moment : moment.subtract(_leadTime);
  if (!at.isAfter(now)) return null;
  return (
    id: offset * 10 + index,
    title: l.jumuah,
    body: atAthan ? l.reminderJumuahNow : l.reminderJumuahSoon,
    at: at,
    sound: atAthan ? sound : ReminderSound.standard,
  );
}
