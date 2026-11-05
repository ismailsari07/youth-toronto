import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/news/mosque_news.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/mosque_news_provider.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/motion.dart';
import '../../community/widgets/news_card.dart';

/// "Camimizden Haberler" on the home screen: featured first, then a horizontal
/// scroll. Carries its own top gap and hides when there's nothing to show. The
/// cards are narrow on purpose, to keep the day's times from moving far down.
class NewsRail extends ConsumerWidget {
  const NewsRail({super.key});

  static const cardWidth = 188.0;
  static const maxItems = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(contentProvider.select((c) => c.features.news));
    // With Events and Announcements both off there's no Community tab to open.
    final hasTab = ref.watch(contentProvider.select((c) => c.showCommunity));
    final items = on
        ? newsRailOrder(
            ref.watch(mosqueNewsProvider).valueOrNull ?? const [],
          ).take(maxItems).toList()
        : const <MosqueNews>[];
    final l = context.l10n;

    return FadeSwitch(
      animateSize: true,
      child: items.isEmpty
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Column(
              key: const ValueKey('news'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(
                  title: l.newsSection,
                  trailingText: hasTab ? l.seeAll : null,
                  onTrailingTap: hasTab
                      ? () {
                          ref.read(communitySegmentProvider.notifier).state =
                              CommunitySegment.news;
                          StatefulNavigationShell.of(context).goBranch(1);
                        }
                      : null,
                ),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                _Rail(items: items),
              ],
            ),
    );
  }
}

/// Wider than the page's gutters, so the cards scroll to the screen's edges.
class _Rail extends StatelessWidget {
  const _Rail({required this.items});

  final List<MosqueNews> items;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      fit: OverflowBoxFit.deferToChild,
      minWidth: 0,
      maxWidth: MediaQuery.sizeOf(context).width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.pageGutter),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                SizedBox(
                  width: NewsRail.cardWidth,
                  child: NewsCard(
                    item: item,
                    compact: true,
                    onTap: () => context.push('/community/news', extra: item),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
