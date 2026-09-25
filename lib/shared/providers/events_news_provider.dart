import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_schedule.dart';
import '../../core/events_news_service.dart';
import '../../core/mosque_time.dart';
import '../../core/models.dart';

/// Upcoming events: recurring ones at their next session, one-off ones from
/// the start of today on the mosque's calendar, soonest first. The single
/// rule shared by the Events list, the header and the detail screen.
final eventsProvider = FutureProvider<List<UpcomingEvent>>((ref) async {
  final events = await EventsNewsService.fetchEvents();
  return upcomingEvents(events, mosqueNow());
});

final newsProvider = FutureProvider<List<Announcement>>((ref) async {
  return EventsNewsService.fetchAnnouncements();
});
