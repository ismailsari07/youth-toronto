import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/event_schedule.dart';
import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../shared/providers/unread_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/announcement_card.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/event_card.dart';
import '../../../ui/components/motion.dart';
import '../../../ui/components/refreshable.dart';
import '../../../ui/components/stagger.dart';

/// Spec §7.3 / §7.4 — Events and Announcements behind one segmented control.
/// Phase B builds the structure; card detail work lands in phases D and E.
/// The panel's feature toggles can turn either off: then the other shows
/// alone, without the control.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  int _segment = 0;
  bool _visible = false;

  /// With events turned off, announcements are the only list, so opening
  /// the tab is what marks them read (there is no segment to tap).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    if (visible && !_visible && !ref.read(contentProvider).showEvents) {
      _markSeenSoon();
    }
    _visible = visible;
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(contentProvider.select((c) => c.features));
    final bothShown = features.events && features.announcements;
    // 0 = events, 1 = announcements; the toggles override the tapped one.
    final segment = !features.events
        ? 1
        : !features.announcements
            ? 0
            : _segment;
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull ?? const <UpcomingEvent>[];
    final eventsLoading = eventsAsync.isLoading && !eventsAsync.hasValue;
    final newsAsync = ref.watch(newsProvider);
    final news = newsAsync.valueOrNull ?? const <Announcement>[];
    final newsLoading = newsAsync.isLoading && !newsAsync.hasValue;
    final jumaa = ref.watch(prayerProvider).valueOrNull?.jumaaPrayerTime;
    final l = context.l10n;

    return RefreshableList(
      onRefresh: () async {
        ref.invalidate(eventsProvider);
        ref.invalidate(newsProvider);
        await Future.wait([
          ref.read(eventsProvider.future),
          ref.read(newsProvider.future),
        ]);
      },
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      // The tab's entrance cascade: header, segment, then each card.
      children: [
        StaggerItem(
          index: 0,
          child: GradientTabHeader(
            title: l.tabCommunity,
            // Cross-fades when the segment, or what it leads with, changes.
            row: FadeSwitch(
              child: KeyedSubtree(
                key: ValueKey((
                  segment,
                  segment == 0
                      ? events.firstOrNull?.event.title
                      : news.firstOrNull?.title,
                )),
                child: _headerRow(segment, events, news, jumaa),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (bothShown) ...[
          StaggerItem(
            index: 1,
            child: AppSegmented(
              labels: [l.events, l.announcements],
              index: segment,
              onChanged: _onSegmentChanged,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Shimmer → list, and one segment → the other, cross-fade. No size
        // animation: the lists can be long, and the fade covers the jump.
        FadeSwitch(
          child: Column(
            key: ValueKey(
              segment == 0
                  ? (eventsLoading ? 'events-loading' : 'events')
                  : (newsLoading ? 'news-loading' : 'news'),
            ),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: segment == 0
                ? (eventsLoading ? _loadingCards() : _events(events))
                // Shimmer while announcements load, so "No announcements"
                // never flashes before they arrive.
                : (newsLoading
                      ? _loadingCards(announcement: true)
                      : _announcements(news)),
          ),
        ),
      ],
    );
  }

  /// The row always carries live content: the next event, else Jumu'ah,
  /// which is never empty (spec §4.7).
  Widget _headerRow(
    int segment,
    List<UpcomingEvent> events,
    List<Announcement> news,
    String? jumaa,
  ) {
    final l = context.l10n;
    if (segment == 1 && news.isNotEmpty) {
      final latest = news.first;
      return HeroRow(
        icon: AppIcons.announcement,
        title: latest.title,
        subtitle: l.postedAgo(timeAgo(l, latest.date)),
        trailing: latest.isNew
            ? AppBadge(
                label: l.newBadge,
                fill: AppColor.heroArcTrack,
                height: 24,
                fontSize: 11,
                letterSpacing: 0,
                horizontalPadding: 10,
              )
            : null,
      );
    }
    if (segment == 0 && events.isNotEmpty) {
      final next = events.first;
      return HeroRow(
        icon: AppIcons.calendar,
        title: next.event.title,
        subtitle: nextSessionLine(l, next),
        trailing: AppBadge(
          label: _inDays(l, next.startsAt),
          fill: AppColor.heroArcTrack,
          height: 24,
          fontSize: 11,
          letterSpacing: 0,
          horizontalPadding: 10,
        ),
      );
    }
    return HeroRow(
      icon: AppIcons.mosque,
      title: l.jumuah,
      subtitle: jumaa == null
          ? l.everyFriday
          : l.salahAt(prayerClock12('Dhuhr', jumaa)),
    );
  }

  /// Opening the announcements list is what marks them read (spec §7.4's
  /// unread dot is derived on-device, never from the server).
  void _onSegmentChanged(int index) {
    setState(() => _segment = index);
    if (index == 1) _markSeenSoon();
  }

  void _markSeenSoon() {
    // Captured before the delay so the context is not used across the gap.
    final container = ProviderScope.containerOf(context, listen: false);
    Future<void>.delayed(
      const Duration(milliseconds: 600),
      () => markAnnouncementsSeen(container),
    );
  }

  /// Calendar days until [session] on the mosque's calendar.
  String _inDays(AppLocalizations l, DateTime session) {
    final now = mosqueNow();
    final days = DateTime.utc(session.year, session.month, session.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return l.today;
    if (days == 1) return l.tomorrow;
    return l.inDays(days);
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does nothing rather than crashing */
    }
  }

  Future<void> _share(UpcomingEvent u) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: eventShareText(context.l10n, u, ref.read(contentProvider)),
          subject: u.event.title,
        ),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  /// Spec §7.3b: three shimmer cards at the real radius, never a spinner.
  /// [announcement] shapes them like announcement cards instead of events.
  List<Widget> _loadingCards({bool announcement = false}) => [
    for (var i = 0; i < 3; i++) ...[
      StaggerItem(
        index: 2 + i,
        child: Container(
          height: announcement ? 104 : 176,
          decoration: BoxDecoration(
            color: AppColor.card,
            borderRadius: BorderRadius.circular(
              announcement ? AppRadius.listCard : AppRadius.card,
            ),
            boxShadow: AppShadow.card,
          ),
          padding: announcement
              ? const EdgeInsets.symmetric(vertical: 16, horizontal: 18)
              : const EdgeInsets.all(AppSpace.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              announcement
                  ? const Shimmer(width: 38, height: 38, radius: 12)
                  : const Shimmer(
                      width: 58,
                      height: 64,
                      radius: AppRadius.tile,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Shimmer(width: 180, height: 17),
                    SizedBox(height: 8),
                    Shimmer(width: 140, height: 13),
                    SizedBox(height: 8),
                    Shimmer(width: 110, height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpace.cardGap),
    ],
  ];

  List<Widget> _events(List<UpcomingEvent> events) {
    if (events.isEmpty) {
      return [
        StaggerItem(
          index: 2,
          child: EmptyStateCard(
            icon: AppIcons.mosque,
            title: context.l10n.noEventsTitle,
            body: context.l10n.noEventsBody,
          ),
        ),
      ];
    }
    return [
      for (final (i, e) in events.indexed) ...[
        StaggerItem(
          index: 2 + i,
          child: EventCard(
            upcoming: e,
            onTap: () => context.push('/community/event', extra: e),
            onRegister: () {
              final uri = e.event.registrationUri;
              if (uri != null) _open(uri.toString());
            },
            onShare: () => _share(e),
          ),
        ),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }

  List<Widget> _announcements(List<Announcement> items) {
    if (items.isEmpty) {
      return [
        StaggerItem(
          index: 2,
          child: EmptyStateCard(
            icon: AppIcons.announcement,
            title: context.l10n.noAnnouncementsTitle,
            body: context.l10n.noAnnouncementsBody,
          ),
        ),
      ];
    }
    final unread = ref.watch(unreadAnnouncementsProvider).map((a) => a.id).toSet();
    return [
      for (final (i, a) in items.indexed) ...[
        StaggerItem(
          index: 2 + i,
          child: AnnouncementCard(
            item: a,
            unread: unread.contains(a.id),
            onTap: () => context.push('/community/announcement', extra: a),
          ),
        ),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }
}
