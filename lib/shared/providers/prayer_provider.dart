import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/notification_service.dart';
import '../../core/prayer_service.dart';

final prayerProvider = FutureProvider<PrayerCachePayload?>((ref) async {
  final payload = await PrayerService.fetchTodayPrayer();
  if (payload != null) {
    // Reminders are best-effort: a notification failure must never stop
    // prayer times from loading.
    try {
      await NotificationService.requestPermissions();
      await NotificationService.schedulePrayerNotifications(
        payload.dailyPrayerTimes,
      );
    } catch (e) {
      debugPrint('prayerProvider: scheduling reminders failed: $e');
    }
  }
  return payload;
});
