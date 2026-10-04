import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/unread_provider.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/announcement_card.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/event_card.dart';
import '../../../ui/components/motion.dart';

/// The Prayer home's glimpse of Community: the next event and the latest
/// announcement, with "See all" switching to the Community tab. Built on the
/// same providers as the Community tab, so the next event is the one at the
/// top of its list (recurring programmes at their next session).
///
/// Carries its own top gap, so when there is nothing to show — no events
/// and no announcements, or both failed to load — the section disappears
/// without leaving a hole. While both are still loading a shimmer card holds
/// the place; whatever arrives cross-fades in.
class CommunitySection extends ConsumerWidget {
  const CommunitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final news = ref.watch(newsProvider);
    final next = events.valueOrNull?.firstOrNull;
    final latest = news.valueOrNull?.firstOrNull;
    final loading = (events.isLoading && !events.hasValue) ||
        (news.isLoading && !news.hasValue);
    final l = context.l10n;

    final Widget content;
    if (next == null && latest == null) {
      content = loading
          ? _frame(
              key: const ValueKey('loading'),
              header: SectionHeader(title: l.homeCommunitySection),
              cards: const [_ShimmerCard()],
            )
          : const SizedBox.shrink(key: ValueKey('none'));
    } else {
      final unread = latest != null &&
          ref.watch(unreadAnnouncementsProvider).any((a) => a.id == latest.id);
      content = _frame(
        key: ValueKey(('content', next != null, latest != null)),
        header: SectionHeader(
          title: l.homeCommunitySection,
          trailingText: l.seeAll,
          onTrailingTap: () => StatefulNavigationShell.of(context).goBranch(1),
        ),
        cards: [
          if (next != null)
            EventCard(
              upcoming: next,
              compact: true,
              onTap: () => context.push('/community/event', extra: next),
            ),
          if (latest != null)
            AnnouncementCard(
              item: latest,
              unread: unread,
              onTap: () =>
                  context.push('/community/announcement', extra: latest),
            ),
        ],
      );
    }

    return FadeSwitch(animateSize: true, child: content);
  }

  Widget _frame({
    required Key key,
    required Widget header,
    required List<Widget> cards,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.cardGapWide),
        header,
        const SizedBox(height: AppSpace.sectionHeaderGap),
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.cardGap),
          cards[i],
        ],
      ],
    );
  }
}

/// The compact event card's shape while nothing has arrived yet.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(AppSpace.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(width: 58, height: 64, radius: AppRadius.tile),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    );
  }
}
