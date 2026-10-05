import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'mosque_time.dart';
import 'notification_sounds.dart';
import 'reminder_settings.dart';

const _channelId = 'prayer_reminders';
// Android fixes a channel's sound when it is created, so "Silent" needs a
// channel of its own. There is no Android athan recording: it plays as
// standard.
const _silentChannelId = 'prayer_reminders_silent';

/// One reminder to schedule. [at] is an absolute instant (a Toronto
/// TZDateTime), so it fires at the right moment wherever the device is.
typedef Reminder = ({
  int id,
  String title,
  String body,
  tz.TZDateTime at,
  ReminderSound sound,
});

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

  /// Replaces every pending reminder with [reminders]. All date/time logic
  /// lives in ReminderSync; this only talks to the plugin.
  ///
  /// [channelName] is what Android shows for these notifications in the
  /// system settings; re-creating the channel with the same id renames it
  /// when the app's language changes.
  static Future<void> scheduleReminders(
    List<Reminder> reminders, {
    required String channelName,
  }) async {
    await cancelAll();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        channelName,
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _silentChannelId,
        channelName,
        importance: Importance.high,
        playSound: false,
      ),
    );

    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: r.at,
        notificationDetails: _details(r.sound, channelName),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  /// iOS: a named sound plays that file from the app bundle (or the
  /// default sound if the file is missing); no sound at all for Silent.
  static NotificationDetails _details(ReminderSound sound, String channelName) {
    final silent = sound == ReminderSound.silent;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        silent ? _silentChannelId : _channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: !silent,
      ),
      iOS: switch (sound) {
        ReminderSound.athan => const DarwinNotificationDetails(
            presentSound: true,
            sound: NotificationSounds.athanFile,
          ),
        ReminderSound.standard =>
          const DarwinNotificationDetails(presentSound: true),
        ReminderSound.silent =>
          const DarwinNotificationDetails(presentSound: false),
      },
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
