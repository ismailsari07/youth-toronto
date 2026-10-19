import 'package:firebase_messaging/firebase_messaging.dart';

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
/// the short reminder horizon ([reminderDays]) bounds what a missed one
/// leaves wrong.
const prayerRefreshType = 'prayer_refresh';

bool isPrayerRefresh(Map<String, dynamic> data) => data['type'] == prayerRefreshType;

/// Reminders and widget, together. Never throws.
Future<void> refreshPrayerSchedules() async {
  initMosqueTime();
  await Future.wait([ReminderSync.sync(), PrayerWidgetSync.sync()]);
}

/// What a prayer_refresh message and a pull on Prayer run. A variable only
/// so tests can count calls.
Future<void> Function() prayerRefresh = refreshPrayerSchedules;

/// Any push data that arrives (foreground or background): acts only on
/// prayer_refresh. Every other type is a visible notification, handled
/// when tapped.
Future<void> handlePushData(Map<String, dynamic> data) async {
  if (isPrayerRefresh(data)) await prayerRefresh();
}

/// FirebaseMessaging.onBackgroundMessage's handler. On iOS FlutterFire calls
/// it on the app's own engine (the app is woken, or launched, in the
/// background and main() has run), so the widget's platform channel in
/// AppDelegate is there too. iOS gives it about 25 seconds.
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) => handlePushData(message.data);
