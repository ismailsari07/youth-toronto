import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

const _channelId = 'prayer_reminders';
const _channelName = 'Prayer Reminders';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      // Unknown device timezone — keep the package default so plugin init
      // below still runs.
      debugPrint('NotificationService: timezone setup failed: $e');
    }

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
        return await android.requestNotificationsPermission() ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService: permission request failed: $e');
      return false;
    }
  }

  static Future<void> schedulePrayerNotifications(
    List<DailyPrayerItem> prayers,
  ) async {
    await cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var id = 0;

    for (final prayer in prayers) {
      if (prayer.name == 'Sunrise') continue;
      final iqamah = prayer.iqamah;
      if (iqamah == null) continue;

      final parts = iqamah.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final fireTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(const Duration(minutes: 5));

      if (fireTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id: id++,
        title: prayer.name,
        body: 'Iqamah in 5 minutes',
        scheduledDate: fireTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
