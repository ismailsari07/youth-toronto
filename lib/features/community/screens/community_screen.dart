import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

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
    final events = ref.watch(eventsProvider).valueOrNull ?? const <YouthEvent>[];
    final news =
        ref.watch(newsProvider).valueOrNull ?? const <Announcement>[];
    final jumaa = ref.watch(prayerProvider).valueOrNull?.jumaaPrayerTime;

    return ListView(
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
          labels: const ['Events', 'Announcements'],
          index: _segment,
          onChanged: (i) => setState(() => _segment = i),
        ),
        const SizedBox(height: 16),
        if (_segment == 0) ..._events(events) else ..._announcements(news),
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

  String _inDays(DateTime dt) {
    final days = dt.difference(DateTime.now()).inHours ~/ 24;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  List<Widget> _events(List<YouthEvent> events) {
    if (events.isEmpty) {
      return [
        const EmptyStateCard(
          icon: AppIcons.mosque,
          title: 'No events scheduled',
          body: 'When the mosque publishes an event it will appear here. '
              "Jumu'ah runs every Friday as usual.",
        ),
      ];
    }
    return [
      for (final e in events) ...[
        _eventCard(e),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }

  Widget _eventCard(YouthEvent event) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateBadge(date: event.dateTime),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppText.cardTitle.c(AppColor.ink)),
                const SizedBox(height: 5),
                Text(
                  heroDateTime(event.dateTime),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
                      .c(AppColor.ink2),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const AppIcon(AppIcons.pin, size: 13, color: AppColor.ink3),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.c(AppColor.ink3),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _announcements(List<Announcement> items) {
    if (items.isEmpty) {
      return [
        const EmptyStateCard(
          icon: AppIcons.announcement,
          title: 'No announcements',
          body: 'Notices from the mosque office will appear here.',
        ),
      ];
    }
    return [
      for (final a in items) ...[
        _announcementCard(a),
        const SizedBox(height: AppSpace.cardGap),
      ],
    ];
  }

  Widget _announcementCard(Announcement item) {
    return AppCard(
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
                Text(
                  item.title,
                  style: AppText.rowTitle
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2)
                      .c(AppColor.ink),
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
    );
  }
}
