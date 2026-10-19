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
/// 5 minutes before the iqamah, as many whole days ahead as fit in iOS's
/// pending limit ([reminderBudget]), in Toronto time, only from real
/// prayer_cache rows (see [scheduleDays]), plus the "open the app" notice on
/// the last of those days (see [buildNotice]).
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

  static Future<bool>? _inFlight;
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
  static Future<void> Function(
    List<Reminder>, {
    required String channelName,
    Reminder? notice,
  }) schedule = NotificationService.scheduleReminders;

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
  ///
  /// Completes with whether the last run replaced the pending reminders from
  /// fresh rows (false when off, not allowed, offline or failed).
  static Future<bool> sync({bool ask = false}) {
    _askQueued |= ask;
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    return _inFlight = _loop();
  }

  static Future<bool> _loop() async {
    try {
      var scheduled = false;
      do {
        _rerun = false;
        final ask = _askQueued;
        _askQueued = false;
        scheduled = await _run(ask: ask);
      } while (_rerun);
      return scheduled;
    } finally {
      _inFlight = null;
    }
  }

  static Future<bool> _run({required bool ask}) async {
    try {
      if (!kPrayerRemindersEnabled) {
        // Switched off: cancel anything an earlier build scheduled, and
        // never ask for permission.
        await NotificationService.cancelPending();
        return false;
      }
      final settings = await loadSettings();
      if (!settings.active) {
        // Cancels the notice too: it only makes sense with reminders on.
        await NotificationService.cancelAll();
        return false;
      }
      final allowed = ask ? await askPermission() : await permissionGranted();
      // Not allowed: nothing would show. The sheet explains it.
      if (allowed == false) return false;

      final List<PrayerDay> days;
      try {
        days = await fetchDays(first: 0, last: maxReminderDays - 1);
      } catch (e) {
        // Offline or server error: keep the notifications already
        // scheduled (the notice included). They came from real rows.
        debugPrint('ReminderSync: loading prayer days failed: $e');
        return false;
      }

      // Notification text is fixed when scheduled, so it is written in the
      // language the app shows now; changing language re-runs this sync.
      final l = await currentAppLocalizations();
      final sound = settings.soundWith(
        athanBundled: await NotificationSounds.athanBundled(),
      );
      // No rows at all is real too: everything pending is cleared. The
      // notice moves with every run, so someone who opens the app regularly
      // never sees it.
      final now = mosqueNow();
      final reminders = buildReminders(days, settings, l, now: now, sound: sound);
      await schedule(
        reminders,
        channelName: l.prayerReminders,
        notice: buildNotice(days, reminders, l, now: now, sound: sound),
      );
      return true;
    } catch (e) {
      debugPrint('ReminderSync: sync failed: $e');
      return false;
    }
  }
}

const _prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _leadTime = Duration(minutes: 5);

/// iOS keeps at most 64 pending local notifications per app and silently
/// drops the rest.
const iosPendingLimit = 64;

/// Local notifications the app schedules besides the prayer reminders and
/// the notice: none. Event and announcement pushes are remote and don't
/// count. Anything added later must be counted here.
const otherLocalNotifications = 0;

/// Slots kept for the "open the app" notice ([buildNotice]).
const noticeSlots = 1;

/// Pending prayer reminders at most: 63. Whole days are scheduled while the
/// next one still fits: 12 days with all five prayers on, 21 with three,
/// and with one prayer as many days as prayer_cache has real rows.
const reminderBudget = iosPendingLimit - otherLocalNotifications - noticeSlots;

/// Days asked of prayer_cache, today included. Only a ceiling: the table
/// holds about 30 days, and the budget ends the schedule long before 90
/// (a day costs a slot unless none of its chosen prayers is ahead).
const maxReminderDays = 90;

/// Every notification [settings] asks for, in time order, from real rows
/// only (a day without its own row gets nothing), as many whole
/// mosque-calendar days from [now] as fit in [budget]: the first day that
/// doesn't fit ends the schedule, so no day is ever half-scheduled. At athan
/// time they use [sound]; 5 minutes before the iqamah, always the standard
/// sound.
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
  int budget = reminderBudget,
}) {
  if (!settings.active) return const [];
  final atAthan = settings.timing == ReminderTiming.atAthan;
  final reminders = <Reminder>[];

  for (final (offset: i, :day, :payload)
      in scheduleDays(days, now, count: maxReminderDays)) {
    final daily = <Reminder>[];
    for (final item in payload.dailyPrayerTimes) {
      final index = _prayerOrder.indexOf(item.name);
      if (index < 0 || !settings.prayers.contains(item.name)) continue;
      if (item.name == 'Dhuhr' && day.weekday == DateTime.friday) {
        final jumuah = _jumuah(i, index, day, payload, l,
            now: now, atAthan: atAthan, sound: sound);
        if (jumuah != null) daily.add(jumuah);
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

      daily.add((
        id: i * 10 + index,
        title: l.prayer(key),
        body: body,
        at: at,
        sound: atAthan ? sound : ReminderSound.standard,
      ));
    }
    if (reminders.length + daily.length > budget) break;
    reminders.addAll(daily);
  }
  return reminders;
}

/// The notice's id: clear of the reminders' `day * 10 + prayer` ids.
const noticeId = 9999;

/// The "open the app" notice for the last day [reminders] cover, or null
/// when there are none or no moment fits. It fires at 10:00 Toronto time
/// that day; if that has passed, in the middle of the first gap between
/// prayers that is still ahead and outside quiet hours (21:30–08:00).
/// Silent when the member chose silent, else the standard sound.
Reminder? buildNotice(
  List<PrayerDay> days,
  List<Reminder> reminders,
  AppLocalizations l, {
  required tz.TZDateTime now,
  required ReminderSound sound,
}) {
  if (reminders.isEmpty) return null;
  final lastAt = reminders.last.at;
  final last = DateTime(lastAt.year, lastAt.month, lastAt.day);
  final payload = scheduleDays(days, last, count: 1).firstOrNull?.payload;
  if (payload == null) return null;
  final at = noticeTime(last, payload, now);
  if (at == null) return null;
  return (
    id: noticeId,
    title: l.prayerReminders,
    body: l.remindersEndingNotice,
    at: at,
    sound: sound == ReminderSound.silent
        ? ReminderSound.silent
        : ReminderSound.standard,
  );
}

const _noticeHour = 10;
// Quiet hours: 21:30–08:00, as minutes since midnight.
const _quietEnds = 8 * 60;
const _quietStarts = 21 * 60 + 30;

/// When the notice for [day] fires, as of [now] (see [buildNotice]). A gap
/// runs from the end of one prayer (its iqamah, or its athan if later) to
/// the next prayer's athan; Friday's Dhuhr is Jumu'ah. A prayer whose time
/// can't be read closes the gaps on both sides of it, so the notice never
/// lands on a prayer nobody could place.
tz.TZDateTime? noticeTime(
  DateTime day,
  PrayerCachePayload payload,
  tz.TZDateTime now,
) {
  final ten = tz.TZDateTime(mosqueTz, day.year, day.month, day.day, _noticeHour);
  if (ten.isAfter(now)) return ten;

  final byName = {for (final p in payload.dailyPrayerTimes) p.name: p};
  final spans = <({tz.TZDateTime start, tz.TZDateTime end})?>[];
  for (final name in _prayerOrder) {
    final item = byName[name];
    tz.TZDateTime? start, end;
    if (name == 'Dhuhr' && day.weekday == DateTime.friday) {
      final time = payload.jumaaPrayerTime;
      start = end = time == null ? null : prayerMoment(day, 'Dhuhr', time);
    } else if (item != null) {
      start = prayerMoment(day, name, item.time);
      final iqamah = item.iqamah;
      final i = iqamah == null ? null : prayerMoment(day, name, iqamah);
      end = start == null || i == null || i.isBefore(start) ? start : i;
    }
    spans.add(start == null || end == null ? null : (start: start, end: end));
  }

  for (var k = 0; k + 1 < spans.length; k++) {
    final before = spans[k], after = spans[k + 1];
    if (before == null || after == null || !after.start.isAfter(before.end)) {
      continue;
    }
    final half = after.start.difference(before.end) ~/ 2;
    final mid = before.end.add(Duration(minutes: half.inMinutes));
    final minutes = mid.hour * 60 + mid.minute;
    if (mid.isAfter(now) && minutes >= _quietEnds && minutes < _quietStarts) {
      return mid;
    }
  }
  return null;
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
