import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/event_schedule.dart';
import '../../core/events_news_service.dart';
import '../../core/models.dart';
import '../../core/mosque_time.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_buttons.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_scaffolding.dart';
import '../community/screens/announcement_detail_screen.dart';
import '../community/screens/event_detail_screen.dart';

/// A tapped notification's event, loaded by id: it may not be in the list
/// the app has (or has loaded yet). With [occurrence] (yyyy-mm-dd), a
/// recurring event shows that day's session.
class EventByIdScreen extends StatefulWidget {
  const EventByIdScreen({super.key, required this.id, this.occurrence});

  final String id;
  final String? occurrence;

  @override
  State<EventByIdScreen> createState() => _EventByIdScreenState();
}

class _EventByIdScreenState extends State<EventByIdScreen> {
  late Future<YouthEvent?> _future = EventsNewsService.fetchEvent(widget.id);

  /// The session to show: the one on [EventByIdScreen.occurrence] if
  /// given, else the next one from today.
  UpcomingEvent _upcoming(YouthEvent event) {
    final day = DateTime.tryParse(widget.occurrence ?? '');
    final from = day == null
        ? mosqueStartOfDay(mosqueNow())
        : tz.TZDateTime(mosqueTz, day.year, day.month, day.day);
    return UpcomingEvent(event, nextOccurrence(event, from));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<YouthEvent?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _LoadingPage(eyebrow: l.eventEyebrow);
        }
        if (snap.hasError) {
          return _MessagePage(
            eyebrow: l.eventEyebrow,
            icon: AppIcons.calendar,
            title: l.errorNetwork,
            onRetry: () => setState(
              () => _future = EventsNewsService.fetchEvent(widget.id),
            ),
          );
        }
        final event = snap.data;
        if (event == null) {
          return _MessagePage(
            eyebrow: l.eventEyebrow,
            icon: AppIcons.calendar,
            title: l.eventGone,
            body: l.goneBody,
          );
        }
        return EventDetailScreen(upcoming: _upcoming(event));
      },
    );
  }
}

/// A tapped notification's announcement, loaded by id. Gone, expired or
/// archived ones get a message instead.
class AnnouncementByIdScreen extends StatefulWidget {
  const AnnouncementByIdScreen({super.key, required this.id});

  final String id;

  @override
  State<AnnouncementByIdScreen> createState() => _AnnouncementByIdScreenState();
}

class _AnnouncementByIdScreenState extends State<AnnouncementByIdScreen> {
  late Future<Announcement?> _future =
      EventsNewsService.fetchAnnouncement(widget.id);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<Announcement?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _LoadingPage(eyebrow: l.announcementEyebrow);
        }
        if (snap.hasError) {
          return _MessagePage(
            eyebrow: l.announcementEyebrow,
            icon: AppIcons.announcement,
            title: l.errorNetwork,
            onRetry: () => setState(
              () => _future = EventsNewsService.fetchAnnouncement(widget.id),
            ),
          );
        }
        final item = snap.data;
        if (item == null) {
          return _MessagePage(
            eyebrow: l.announcementEyebrow,
            icon: AppIcons.announcement,
            title: l.announcementGone,
            body: l.goneBody,
          );
        }
        return AnnouncementDetailScreen(item: item);
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.eyebrow});

  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PlainNavBar(eyebrow: eyebrow, title: ''),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.pageGutter,
              8,
              AppSpace.pageGutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 220, height: 24),
                SizedBox(height: 22),
                Shimmer(width: double.infinity, height: 180, radius: 26),
                SizedBox(height: AppSpace.cardGap),
                Shimmer(width: double.infinity, height: 128, radius: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({
    required this.eyebrow,
    required this.icon,
    required this.title,
    this.body,
    this.onRetry,
  });

  final String eyebrow;
  final String icon;
  final String title;
  final String? body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = body;
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PlainNavBar(eyebrow: eyebrow, title: ''),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.pageGutter,
              8,
              AppSpace.pageGutter,
              40,
            ),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.iconCircle,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      icon,
                      size: 32,
                      color: context.colors.selected,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ).c(context.colors.ink),
                  ),
                  if (text != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, height: 1.45)
                          .c(context.colors.ink2),
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 18),
                    GhostButton(label: context.l10n.tryAgain, onTap: onRetry),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
