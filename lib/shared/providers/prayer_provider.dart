import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/notification_service.dart';
import '../../core/prayer_service.dart';

final prayerProvider = FutureProvider<PrayerCachePayload?>((ref) async {
  final payload = await PrayerService.fetchTodayPrayer();
  if (payload != null) {
    await NotificationService.schedulePrayerNotifications(
      payload.dailyPrayerTimes,
    );
  }
  return payload;
});
