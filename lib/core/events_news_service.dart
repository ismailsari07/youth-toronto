import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class EventsNewsService {
  static Future<List<YouthEvent>> fetchEvents() async {
    try {
      final rows = await Supabase.instance.client
          .from('youth_events')
          .select()
          .order('date_time');
      return rows.map((row) => YouthEvent.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<NewsItem>> fetchNews() async {
    try {
      final rows = await Supabase.instance.client
          .from('news')
          .select()
          .order('created_at', ascending: false);
      return rows.map((row) => NewsItem.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }
}
