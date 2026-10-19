import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mosque_time.dart';
import 'prayer_widget_sync.dart';
import 'reminder_sync.dart';

/// The silent push pape-admin sends after any change to a prayer_cache row
/// dated today or later (debounced on the server): data
/// `{"type": "prayer_refresh"}`, `content-available: 1`, no alert. The app
/// then reschedules its reminders and rewrites the widget from fresh rows.
///
/// iOS delivers these at its own discretion (not after the app was swiped
/// away, often not in Low Power Mode or with Background App Refresh off), so
/// nothing depends on them: launch, resume and pull-to-refresh sync too, and
/// the "open the app" notice on the last scheduled day (see buildNotice)
/// asks the member to open the app before the reminders run out.
const prayerRefreshType = 'prayer_refresh';

bool isPrayerRefresh(Map<String, dynamic> data) => data['type'] == prayerRefreshType;

/// Reminders and widget, together. Never throws. Completes with whether the
/// reminders were rescheduled from fresh rows.
Future<bool> refreshPrayerSchedules() async {
  initMosqueTime();
  final (rescheduled, _) =
      await (ReminderSync.sync(), PrayerWidgetSync.sync()).wait;
  return rescheduled;
}

/// What a prayer_refresh message and a pull on Prayer run. A variable only
/// so tests can count calls.
Future<bool> Function() prayerRefresh = refreshPrayerSchedules;

/// Any push data that arrives (foreground or, with [background], at
/// [onBackgroundPush]): acts only on prayer_refresh. Every other type is a
/// visible notification, handled when tapped. A background refresh that
/// rescheduled is written down for Profil → Uygulama hakkında.
Future<void> handlePushData(
  Map<String, dynamic> data, {
  bool background = false,
}) async {
  if (!isPrayerRefresh(data)) return;
  final rescheduled = await prayerRefresh();
  if (background && rescheduled) await BackgroundRefreshLog.record(DateTime.now());
}

/// The last time a prayer_refresh silent push rescheduled the reminders in
/// the background, on this device only: shown in the About sheet so a
/// TestFlight check can tell whether iOS delivered the push.
abstract final class BackgroundRefreshLog {
  static const _key = 'last_background_prayer_refresh';

  static Future<void> record(DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, at.toUtc().toIso8601String());
    } catch (e) {
      debugPrint('BackgroundRefreshLog: saving failed: $e');
    }
  }

  /// In the device's local time; null if it never happened.
  static Future<DateTime?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    } catch (_) {
      return null;
    }
  }
}

/// FirebaseMessaging.onBackgroundMessage's handler. On iOS FlutterFire calls
/// it on the app's own engine (the app is woken, or launched, in the
/// background and main() has run), so the widget's platform channel in
/// AppDelegate is there too. iOS gives it about 25 seconds.
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) =>
    handlePushData(message.data, background: true);
