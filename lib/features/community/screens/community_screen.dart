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
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../shared/providers/unread_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/event_card.dart';
import '../../../ui/components/refreshable.dart';

/// Spec §7.3 / §7.4 — Events and Announcements behind one segmented control.
/// Phase B builds the structure; card detail work lands in phases D and E.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull ?? const <UpcomingEvent>[];
    final eventsLoading = eventsAsync.isLoading && !eventsAsync.hasValue;
    final news =
        ref.watch(newsProvider).valueOrNull ?? const <Announcement>[];
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
      children: [
        GradientTabHeader(
          title: l.tabCommunity,
          row: _headerRow(events, news, jumaa),
        ),
        const SizedBox(height: 16),
        AppSegmented(
          labels: [l.events, l.announcements],
          index: _segment,
          onChanged: _onSegmentChanged,
        ),
        const SizedBox(height: 16),
        if (_segment == 0)
          ...(eventsLoading ? _loadingCards() : _events(events))
        else
          ..._announcements(news),
      ],
    );
  }

  /// The row always carries live content: the next event, else Jumu'ah,
  /// which is never empty (spec §4.7).
  Widget _headerRow(
    List<UpcomingEvent> events,
    List<Announcement> news,
    String? jumaa,
  ) {
    final l = context.l10n;
    if (_segment == 1 && news.isNotEmpty) {
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
    if (_segment == 0 && events.isNotEmpty) {
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
      title: l.jumuahThisFriday,
      subtitle: jumaa == null
          ? l.everyFriday
          : l.salahAt(prayerClock12('Dhuhr', jumaa)),
    );
  }

  /// Opening the announcements list is what marks them read (spec §7.4's
  /// unread dot is derived on-device, never from the server).
  void _onSegmentChanged(int index) {
    setState(() => _segment = index);
    if (index == 1) {
      // Captured before the delay so the context is not used across the gap.
      final container = ProviderScope.containerOf(context, listen: false);
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        () => markAnnouncementsSeen(container),
      );
    }
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
          text: eventShareText(context.l10n, u),
          subject: u.event.title,
        ),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  /// Spec §7.3b: three shimmer cards at the real radius, never a spinner.
  List<Widget> _loadingCards() => [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: AppColor.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadow.card,
            ),
            padding: const EdgeInsets.all(AppSpace.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Shimmer(width: 58, height: 64, radius: AppRadius.tile),
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
          const SizedBox(height: AppSpace.cardGap),
        ],
      ];

  List<Widget> _events(List<UpcomingEvent> events) {
    if (events.isEmpty) {
      return [
        EmptyStateCard(
          icon: AppIcons.mosque,
          title: context.l10n.noEventsTitle,
          body: context.l10n.noEventsBody,
        ),
      ];
    }
    return [
      for (final e in events) ...[
        EventCard(
          upcoming: e,
          onTap: () => context.push('/community/event', extra: e),
          onRegister: () {
            final uri = e.event.registrationUri;
            if (uri != null) _open(uri.toString());
          },
          onShare: () => _share(e),
        ),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }

  List<Widget> _announcements(List<Announcement> items) {
    if (items.isEmpty) {
      return [
        EmptyStateCard(
          icon: AppIcons.announcement,
          title: context.l10n.noAnnouncementsTitle,
          body: context.l10n.noAnnouncementsBody,
        ),
      ];
    }
    final unread = ref.watch(unreadAnnouncementsProvider).map((a) => a.id).toSet();
    return [
      for (final a in items) ...[
        _announcementCard(a, unread: unread.contains(a.id)),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }

  Widget _announcementCard(Announcement item, {required bool unread}) {
    return GestureDetector(
      onTap: () => context.push('/community/announcement', extra: item),
      behavior: HitTestBehavior.opaque,
      child: AppCard(
      radius: AppRadius.listCard,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(
            icon: AppIcons.announcement,
            tone: RowTone.blue,
            square: true,
          ),
          const SizedBox(width: AppSpace.rowGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppText.rowTitle
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            )
                            .c(AppColor.ink),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 4, top: 6),
                        decoration: const BoxDecoration(
                          color: AppColor.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.45)
                      .c(AppColor.ink2),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.postedAgo(timeAgo(context.l10n, item.date)),
                  style: const TextStyle(fontSize: 12).c(AppColor.ink3),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
