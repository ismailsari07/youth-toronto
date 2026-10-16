import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_schedule.dart';
import 'models.dart';
import 'mosque_time.dart';

class EventsNewsService {
  /// One-off events from the start of today (mosque calendar) onward, plus
  /// every recurring event whatever its stored first date — a weekly
  /// programme that began last month is still on. Which session to show is
  /// worked out on the device (event_schedule.dart). Errors propagate.
  static Future<List<YouthEvent>> fetchEvents() async {
    final cutoff = mosqueStartOfDay(mosqueNow()).toUtc().toIso8601String();
    final rows = await Supabase.instance.client
        .from('youth_events')
        .select()
        // RLS already hides drafts from app users, but admins can read every
        // event (for the admin panel); an admin signed into the app must not
        // see drafts either.
        .eq('is_published', true)
        .or('date_time.gte.$cutoff,recurrence.in.(weekly,biweekly,monthly)')
        .order('date_time');
    return rows.map((row) => YouthEvent.fromJson(row)).toList();
  }

  /// One event by id, for a tapped notification; null when it's gone or
  /// unpublished (filtered here too: admins can read drafts).
  static Future<YouthEvent?> fetchEvent(String id) async {
    final row = await Supabase.instance.client
        .from('youth_events')
        .select()
        .eq('id', id)
        .eq('is_published', true)
        .maybeSingle();
    return row == null ? null : YouthEvent.fromJson(row);
  }

  /// One announcement by id, for a tapped notification; null when it's
  /// gone, archived, a draft or expired.
  static Future<Announcement?> fetchAnnouncement(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await Supabase.instance.client
        .from('announcements')
        .select(
          'id, title, description, image_url, image_alt_text, published_at, created_at',
        )
        .eq('id', id)
        .eq('status', 'published')
        .gt('expires_at', now)
        .maybeSingle();
    return row == null ? null : Announcement.fromJson(row);
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
