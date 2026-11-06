import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/event_schedule.dart';
import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../core/news/mosque_news.dart';
import '../../../core/push/push_prompt.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/mosque_news_provider.dart';
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
import '../../push/push_prompt_sheet.dart';
import '../widgets/news_card.dart';

/// Spec §7.3 / §7.4 — Events, Announcements and News behind one segmented
/// control. Phase B builds the structure; card detail work lands in phases D
/// and E. The panel's feature toggles can turn any of them off, and the news
/// segment waits for the first published item; one left shows alone, without
/// the control.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _visible = false;

  /// With events turned off, announcements are the only list, so opening
  /// the tab is what marks them read (there is no segment to tap).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    if (visible && !_visible && _segmentNow() == CommunitySegment.announcements) {
      _markSeenSoon();
    }
    if (visible && !_visible) {
      // Opening the tab may bring up our notifications pre-prompt (once).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          maybeShowPushPrompt(context, ref, PromptTrigger.communityVisit);
        }
      });
    }
    _visible = visible;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(contentProvider.select((c) => c.features));
    ref.watch(communitySegmentProvider);
    final mosqueNews = ref.watch(mosqueNewsProvider).valueOrNull ?? const <MosqueNews>[];
    final segments = _segments();
    final segment = _segmentNow();
    final index = segments.indexOf(segment);
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
        ref.invalidate(mosqueNewsProvider);
        await Future.wait([
          ref.read(eventsProvider.future),
          ref.read(newsProvider.future),
          ref.read(mosqueNewsProvider.future),
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
                  switch (segment) {
                    CommunitySegment.events => events.firstOrNull?.event.title,
                    CommunitySegment.announcements => news.firstOrNull?.title,
                    CommunitySegment.news => mosqueNews.firstOrNull?.title,
                  },
                )),
                child: _headerRow(segment, events, news, mosqueNews, jumaa),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (segments.length > 1) ...[
          StaggerItem(
            index: 1,
            child: AppSegmented(
              labels: [
                for (final s in segments)
                  switch (s) {
                    CommunitySegment.events => l.events,
                    CommunitySegment.announcements => l.announcements,
                    CommunitySegment.news => l.newsSegment,
                  },
              ],
              index: index,
              onChanged: (i) => _onSegmentChanged(segments[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Shimmer → list, and one segment → the other, cross-fade. No size
        // animation: the lists can be long, and the fade covers the jump.
        FadeSwitch(
          child: Column(
            key: ValueKey(switch (segment) {
              CommunitySegment.events => eventsLoading ? 'events-loading' : 'events',
              CommunitySegment.announcements => newsLoading ? 'news-loading' : 'news',
              CommunitySegment.news => 'mosque-news',
            }),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (segment) {
              CommunitySegment.events =>
                eventsLoading ? _loadingCards() : _events(events),
              // Shimmer while announcements load, so "No announcements"
              // never flashes before they arrive.
              CommunitySegment.announcements => newsLoading
                  ? _loadingCards(announcement: true)
                  : _announcements(news),
              CommunitySegment.news => _mosqueNews(mosqueNews),
            },
          ),
        ),
      ],
    );
  }

  /// What the toggles leave, in order; news waits for its first item.
  List<CommunitySegment> _segments() {
    final features = ref.read(contentProvider).features;
    final hasNews = ref.read(mosqueNewsProvider).valueOrNull?.isNotEmpty ?? false;
    return [
      if (features.events) CommunitySegment.events,
      if (features.announcements) CommunitySegment.announcements,
      if (features.news && hasNews) CommunitySegment.news,
    ];
  }

  /// The chosen segment; when it isn't shown, the first that is.
  CommunitySegment _segmentNow() {
    final segments = _segments();
    final chosen = ref.read(communitySegmentProvider);
    return segments.contains(chosen)
        ? chosen
        : segments.firstOrNull ?? CommunitySegment.events;
  }

  /// The row always carries live content: the next event, else Jumu'ah,
  /// which is never empty (spec §4.7).
  Widget _headerRow(
    CommunitySegment segment,
    List<UpcomingEvent> events,
    List<Announcement> news,
    List<MosqueNews> mosqueNews,
    String? jumaa,
  ) {
    final l = context.l10n;
    if (segment == CommunitySegment.news && mosqueNews.isNotEmpty) {
      final latest = mosqueNews.first;
      return HeroRow(
        icon: AppIcons.photo,
        title: latest.title,
        subtitle: newsDay(l, latest.date),
      );
    }
    if (segment == CommunitySegment.announcements && news.isNotEmpty) {
      final latest = news.first;
      return HeroRow(
        icon: AppIcons.announcement,
        title: latest.title,
        subtitle: l.postedAgo(timeAgo(l, latest.date)),
        trailing: latest.isNew
            ? AppBadge(
                label: l.newBadge,
                fill: context.colors.heroArcTrack,
                height: 24,
                fontSize: 11,
                letterSpacing: 0,
                horizontalPadding: 10,
              )
            : null,
      );
    }
    if (segment == CommunitySegment.events && events.isNotEmpty) {
      final next = events.first;
      return HeroRow(
        icon: AppIcons.calendar,
        title: next.event.title,
        subtitle: nextSessionLine(l, next),
        trailing: AppBadge(
          label: _inDays(l, next.startsAt),
          fill: context.colors.heroArcTrack,
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
          : l.salahAt(prayerClockText(l, 'Dhuhr', jumaa)),
    );
  }

  /// Opening the announcements list is what marks them read (spec §7.4's
  /// unread dot is derived on-device, never from the server).
  void _onSegmentChanged(CommunitySegment segment) {
    ref.read(communitySegmentProvider.notifier).state = segment;
    if (segment == CommunitySegment.announcements) _markSeenSoon();
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
            color: context.colors.card,
            borderRadius: BorderRadius.circular(
              announcement ? AppRadius.listCard : AppRadius.card,
            ),
            boxShadow: context.shadows.card,
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
            onTap: () {
              context.push('/community/event', extra: e);
              promptAfterEventTap(context, ref);
            },
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

  List<Widget> _mosqueNews(List<MosqueNews> items) => [
    for (final (i, n) in items.indexed) ...[
      StaggerItem(
        index: 2 + i,
        child: NewsCard(
          item: n,
          onTap: () => context.push('/community/news', extra: n),
        ),
      ),
      const SizedBox(height: AppSpace.cardGap),
    ],
  ];

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
