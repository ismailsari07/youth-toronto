import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/events_news_service.dart';
import '../../core/models.dart';

final eventsProvider = FutureProvider<List<YouthEvent>>((ref) async {
  return EventsNewsService.fetchEvents();
});

final newsProvider = FutureProvider<List<Announcement>>((ref) async {
  return EventsNewsService.fetchAnnouncements();
});
