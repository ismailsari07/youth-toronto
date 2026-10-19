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

  /// The rows from [first] to [last] days from today (Toronto calendar,
  /// inclusive), oldest first. Only rows that are really there: a missing
  /// day stays missing, and a row that can't be read is dropped rather than
  /// failing the rest. Throws when the call itself fails, so callers can
  /// keep what they already have.
  static Future<List<({String date, PrayerCachePayload payload})>> fetchDays({
    required int first,
    required int last,
  }) async {
    // Calendar-day step (not 24h), so a DST change can't skip a date.
    final now = mosqueNow();
    final from = DateTime(now.year, now.month, now.day + first);
    final to = DateTime(now.year, now.month, now.day + last);
    final rows = await Supabase.instance.client
        .from('prayer_cache')
        .select('date, payload')
        .gte('date', mosqueDateKey(from))
        .lte('date', mosqueDateKey(to))
        .order('date');
    final days = <({String date, PrayerCachePayload payload})>[];
    for (final row in rows) {
      try {
        days.add((
          date: row['date'] as String,
          payload: PrayerCachePayload.fromJson(
            row['payload'] as Map<String, dynamic>,
          ),
        ));
      } catch (_) {
        // Unreadable: that day has no data.
      }
    }
    return days;
  }
}
