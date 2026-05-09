import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

const supabaseUrl = 'https://onczqxxdvmmmdcuhmyio.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uY3pxeHhkdm1tbWRjdWhteWlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNjY2NDUsImV4cCI6MjA2Nzc0MjY0NX0.nS7eeii-QiS19Kvwljvs4j4B71KMBrdI94H0gx5ualo';

class PrayerService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static Future<PrayerCachePayload?> fetchTodayPrayer() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final row = await Supabase.instance.client
          .from('prayer_cache')
          .select('payload')
          .eq('date', today)
          .maybeSingle();

      // ignore: avoid_print
      print('row: $row');
      // ignore: avoid_print
      print('error: ${row == null ? "null row" : "ok"}');
      if (row == null) return null;
      return PrayerCachePayload.fromJson(row['payload'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
