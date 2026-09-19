import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../l10n/app_strings.dart';
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
    final events = eventsAsync.valueOrNull ?? const <YouthEvent>[];
    final eventsLoading = eventsAsync.isLoading && !eventsAsync.hasValue;
    final news =
        ref.watch(newsProvider).valueOrNull ?? const <Announcement>[];
    final jumaa = ref.watch(prayerProvider).valueOrNull?.jumaaPrayerTime;

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
          title: 'Community',
          row: _headerRow(events, news, jumaa),
        ),
        const SizedBox(height: 16),
        AppSegmented(
          labels: const [AppStrings.events, AppStrings.announcements],
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
    List<YouthEvent> events,
    List<Announcement> news,
    String? jumaa,
  ) {
    if (_segment == 1 && news.isNotEmpty) {
      final latest = news.first;
      return HeroRow(
        icon: AppIcons.announcement,
        title: latest.title,
        subtitle: 'Posted ${timeAgo(latest.date)}',
        trailing: latest.isNew
            ? const AppBadge(
                label: 'New',
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
        title: next.title,
        subtitle: heroDateTime(next.dateTime),
        trailing: AppBadge(
          label: _inDays(next.dateTime),
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
      title: "Jumu'ah · this Friday",
      subtitle: jumaa == null ? 'Every Friday' : 'Salah $jumaa PM',
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

  String _inDays(DateTime dt) {
    final days = dt.difference(DateTime.now()).inHours ~/ 24;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does nothing rather than crashing */
    }
  }

  Future<void> _share(YouthEvent event) async {
    final lines = <String>[
      event.title,
      heroDateTime(event.dateTime),
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!.trim(),
      if (event.registrationUri != null) 'Register: ${event.registrationUri}',
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(text: lines.join('\n'), subject: event.title),
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

  List<Widget> _events(List<YouthEvent> events) {
    if (events.isEmpty) {
      return [
        const EmptyStateCard(
          icon: AppIcons.mosque,
          title: AppStrings.noEventsTitle,
          body: AppStrings.noEventsBody,
        ),
      ];
    }
    return [
      for (final e in events) ...[
        EventCard(
          event: e,
          onTap: () => context.push('/community/event', extra: e),
          onRegister: () {
            final uri = e.registrationUri;
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
        const EmptyStateCard(
          icon: AppIcons.announcement,
          title: AppStrings.noAnnouncementsTitle,
          body: AppStrings.noAnnouncementsBody,
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
                  'Posted ${timeAgo(item.date)}',
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
