import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'mosque_time.dart';

const supabaseUrl = 'https://onczqxxdvmmmdcuhmyio.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uY3pxeHhkdm1tbWRjdWhteWlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNjY2NDUsImV4cCI6MjA2Nzc0MjY0NX0.nS7eeii-QiS19Kvwljvs4j4B71KMBrdI94H0gx5ualo';

class PrayerService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  /// Today's row on the mosque's (Toronto) calendar, or null if missing.
  static Future<PrayerCachePayload?> fetchTodayPrayer() async {
    try {
      final today = mosqueDateKey(mosqueNow());
      final row = await Supabase.instance.client
          .from('prayer_cache')
          .select('payload')
          .eq('date', today)
          .maybeSingle();
      if (row == null) return null;
      return PrayerCachePayload.fromJson(row['payload'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Rows from Toronto-yesterday onward, oldest first, keyed by date.
  /// Yesterday is included as a fallback for the hours before the daily
  /// cron writes today's row. Throws on failure so callers can keep what
  /// they already have.
  static Future<List<({String date, PrayerCachePayload payload})>>
      fetchRecentDays() async {
    // Calendar-day step (not 24h), so a DST change can't skip a date.
    final now = mosqueNow();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final rows = await Supabase.instance.client
        .from('prayer_cache')
        .select('date, payload')
        .gte('date', mosqueDateKey(yesterday))
        .order('date');
    return [
      for (final row in rows)
        (
          date: row['date'] as String,
          payload: PrayerCachePayload.fromJson(
            row['payload'] as Map<String, dynamic>,
          ),
        ),
    ];
  }
}
