import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/prayer_service.dart';

/// Today's prayer times (mosque calendar). Reminders are scheduled
/// separately by ReminderSync, so they can never delay or break this.
final prayerProvider = FutureProvider<PrayerCachePayload?>((ref) async {
  return PrayerService.fetchTodayPrayer();
});
