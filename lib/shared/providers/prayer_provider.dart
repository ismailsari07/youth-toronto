import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/prayer_days.dart';
import '../../core/prayer_month.dart';
import '../../core/prayer_service.dart';

/// Today's prayer times (mosque calendar). Reminders are scheduled
/// separately by ReminderSync, so they can never delay or break this.
final prayerProvider = FutureProvider<PrayerCachePayload?>((ref) async {
  return PrayerService.fetchTodayPrayer();
});

/// The rows for the monthly view. Reloads when [PrayerRows.forget] says they're
/// out of date; usually answered from what the reminders already fetched.
final prayerMonthProvider = FutureProvider.autoDispose<List<PrayerDay>>((ref) {
  void again() => ref.invalidateSelf();
  PrayerRows.changed.addListener(again);
  ref.onDispose(() => PrayerRows.changed.removeListener(again));
  return PrayerRows.window();
});
