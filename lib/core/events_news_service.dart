import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class EventsNewsService {
  /// Events from the start of today (local) onward, soonest first. Today's
  /// events stay listed all day since there's no end time. Errors propagate.
  static Future<List<YouthEvent>> fetchEvents() async {
    final rows = await Supabase.instance.client
        .from('youth_events')
        .select()
        .gte('date_time', startOfToday().toUtc().toIso8601String())
        .order('date_time');
    return rows.map((row) => YouthEvent.fromJson(row)).toList();
  }

  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Published, unexpired announcements, newest first. Errors propagate so the
  /// screen can show its error state instead of a misleading empty list.
  static Future<List<Announcement>> fetchAnnouncements() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await Supabase.instance.client
        .from('announcements')
        .select(
          'id, title, description, image_url, image_alt_text, published_at, created_at',
        )
        .eq('status', 'published')
        .gt('expires_at', now)
        .order('published_at', ascending: false, nullsFirst: false);
    return rows.map((row) => Announcement.fromJson(row)).toList();
  }
}
