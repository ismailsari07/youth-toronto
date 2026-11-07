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

/// "Camimizden Haberler" on the home screen: featured first. One item fills
/// the width like the Community cards; several swipe sideways, each 88% of
/// the width so the next one peeks in. Carries its own top gap and hides when
/// there's nothing to show.
class NewsRail extends ConsumerWidget {
  const NewsRail({super.key});

  static const maxItems = 8;

  /// A card's share of the content width when there are several.
  static const peekFraction = 0.88;
  static const gap = 12.0;

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

void _open(BuildContext context, MosqueNews item) =>
    context.push('/community/news', extra: item);

/// One card: the content width. Several: a [PageView] as wide as the screen
/// from the left gutter on, pages of a card plus the gap, so each swipe stops
/// with a card at the gutter and the next one peeking in on the right.
class _Rail extends StatefulWidget {
  const _Rail({required this.items});

  final List<MosqueNews> items;

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> {
  PageController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double fraction) {
    final current = _controller;
    if (current != null && current.viewportFraction == fraction) return current;
    final page = current != null && current.hasClients ? current.page?.round() ?? 0 : 0;
    current?.dispose();
    return _controller = PageController(viewportFraction: fraction, initialPage: page);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.length == 1) {
      return HomeNewsCard(
        key: ValueKey('home-news-${items.first.id}'),
        item: items.first,
        onTap: () => _open(context, items.first),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth;
        final screen = MediaQuery.sizeOf(context).width;
        final viewport = screen - AppSpace.pageGutter;
        final card = content * NewsRail.peekFraction;
        final controller = _controllerFor((card + NewsRail.gap) / viewport);
        return OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          fit: OverflowBoxFit.deferToChild,
          minWidth: 0,
          maxWidth: viewport,
          child: SizedBox(
            width: viewport,
            height: HomeNewsCard.heightFor(context, card),
            child: PageView.builder(
              controller: controller,
              padEnds: false,
              clipBehavior: Clip.none,
              itemCount: items.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsetsDirectional.only(end: NewsRail.gap),
                child: HomeNewsCard(
                  key: ValueKey('home-news-${items[i].id}'),
                  item: items[i],
                  onTap: () => _open(context, items[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
