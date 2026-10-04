import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'mosque_time.dart';

const _channelId = 'prayer_reminders';

/// One reminder to schedule. [at] is an absolute instant (a Toronto
/// TZDateTime), so it fires at the right moment wherever the device is.
typedef Reminder = ({int id, String title, String body, tz.TZDateTime at});

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    initMosqueTime();

    // Permissions are requested later via requestPermissions(), not here:
    // this runs before runApp(), and a permission dialog would block the
    // first frame.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
  }

  /// Asks for notification permission on first use. The OS shows its dialog
  /// only once; later calls return the stored answer without prompting.
  static Future<bool> requestPermissions() async {
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              sound: true,
              badge: true,
            ) ??
            false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // null below Android 13, where no runtime permission exists.
        return await android.requestNotificationsPermission() ?? true;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService: permission request failed: $e');
      return false;
    }
  }

  /// Replaces every pending reminder with [reminders]. All date/time logic
  /// lives in ReminderSync; this only talks to the plugin.
  ///
  /// [channelName] is what Android shows for these notifications in the
  /// system settings; re-creating the channel with the same id renames it
  /// when the app's language changes.
  /// Whether iOS currently lets the app show notifications: false once the
  /// member has said no (or turned them off in Settings), null where it
  /// can't be told (other platforms, or before the plugin is ready).
  static Future<bool?> notificationsAllowed() async {
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios == null) return null;
      final options = await ios.checkPermissions();
      if (options == null) return null;
      return options.isEnabled || options.isProvisionalEnabled;
    } catch (e) {
      debugPrint('NotificationService: permission check failed: $e');
      return null;
    }
  }

  static Future<void> scheduleReminders(
    List<Reminder> reminders, {
    required String channelName,
  }) async {
    await cancelAll();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            channelName,
            importance: Importance.high,
          ),
        );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: r.at,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
