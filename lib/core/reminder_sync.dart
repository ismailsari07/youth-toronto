import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'models.dart';
import 'mosque_time.dart';
import 'notification_service.dart';
import 'prayer_service.dart';

typedef _Day = ({String date, PrayerCachePayload payload});

/// Keeps this device's prayer reminders in step with the mosque schedule:
/// 5 minutes before each iqamah, 7 days ahead, in Toronto time.
///
/// The on/off setting lives on the device (reminders are per device), so it
/// works signed in or out. The server's notifications_enabled is only a
/// mirror written by the Profile toggle; scheduling never reads it.
class ReminderSync {
  static const _prefKey = 'prayer_reminders_enabled';
  static const _daysAhead = 7; // 7 × 5 prayers = 35, under iOS's 64 cap
  static const _leadTime = Duration(minutes: 5);
  static const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static Future<void>? _inFlight;
  static bool _rerun = false;

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? true;
    } catch (e) {
      debugPrint('ReminderSync: reading setting failed: $e');
      return true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Safe to call any time; never throws. Only one run at a time: a call made
  /// during a run (e.g. the toggle flipped mid-sync) queues one fresh run
  /// afterwards, so the latest setting and data always win.
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
      if (!await isEnabled()) {
        await NotificationService.cancelAll();
        return;
      }
      await NotificationService.requestPermissions();

      final List<_Day> days;
      try {
        days = await PrayerService.fetchRecentDays();
      } catch (e) {
        // Offline or server error: keep the reminders already scheduled.
        debugPrint('ReminderSync: loading prayer days failed: $e');
        return;
      }
      if (days.isEmpty) return;

      // Reminder text is fixed when scheduled, so it is written in the
      // language the app shows now; changing language re-runs this sync.
      final l = await currentAppLocalizations();
      await NotificationService.scheduleReminders(
        _buildReminders(days, l),
        channelName: l.prayerReminders,
      );
    } catch (e) {
      debugPrint('ReminderSync: sync failed: $e');
    }
  }

  static List<Reminder> _buildReminders(
    List<_Day> days,
    AppLocalizations l,
  ) {
    final byDate = {for (final d in days) d.date: d.payload};
    final now = mosqueNow();
    final reminders = <Reminder>[];

    for (var i = 0; i < _daysAhead; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final key = mosqueDateKey(day);
      // No row yet for future days (prayer_cache only holds up to today):
      // use the latest known day's times, refreshed on every open/resume.
      final payload = byDate[key] ?? _latestOnOrBefore(days, key);
      if (payload == null) continue;

      for (final item in payload.dailyPrayerTimes) {
        final index = _prayers.indexOf(item.name);
        final iqamah = item.iqamah;
        if (index < 0 || iqamah == null) continue; // skips Sunrise
        final moment = prayerMoment(day, item.name, iqamah);
        if (moment == null) continue;
        final at = moment.subtract(_leadTime);
        if (!at.isAfter(now)) continue;
        reminders.add((
          id: i * 10 + index,
          title: l.prayerSalah(item.name.toLowerCase()),
          body: l.reminderBody,
          at: at,
        ));
      }
    }
    return reminders;
  }

  static PrayerCachePayload? _latestOnOrBefore(List<_Day> days, String key) {
    PrayerCachePayload? latest;
    for (final d in days) {
      // yyyy-MM-dd strings compare in date order.
      if (d.date.compareTo(key) <= 0) latest = d.payload;
    }
    return latest;
  }
}
