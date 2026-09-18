import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/events_news_service.dart';
import '../../core/models.dart';

/// Upcoming events only (from the start of today, local): the single rule
/// shared by the Events list, the calendar and Home.
final eventsProvider = FutureProvider<List<YouthEvent>>((ref) async {
  final events = await EventsNewsService.fetchEvents();
  final cutoff = EventsNewsService.startOfToday();
  return events.where((e) => !e.dateTime.isBefore(cutoff)).toList();
});

final newsProvider = FutureProvider<List<Announcement>>((ref) async {
  return EventsNewsService.fetchAnnouncements();
});
