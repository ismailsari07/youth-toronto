import 'package:flutter/material.dart';

import '../../../core/news/mosque_news.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/news_photo.dart';

/// A news item: its cover in 4:5, the date and the title. [compact] is the
/// home rail's card; otherwise the full-width card of the Community list.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final MosqueNews item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = item.slides.length;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(compact ? 18 : AppRadius.card),
            boxShadow: context.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  NewsPhotoFrame(photo: item.cover, fallbackLabel: item.title),
                  if (item.featured)
                    Positioned(
                      left: compact ? 8 : 10,
                      top: compact ? 8 : 10,
                      child: _Pill(
                        label: l.newsFeatured,
                        fill: context.colors.goldBg,
                        ink: context.colors.goldText,
                      ),
                    ),
                  if (!compact && count > 1)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _Pill(
                        label: l.newsPhotoCount(count),
                        fill: const Color(0xCC0A1310),
                        ink: Colors.white,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: compact
                    ? const EdgeInsets.fromLTRB(11, 9, 11, 11)
                    : const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsDay(l, item.date),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ).c(context.colors.ink3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: compact ? 3 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: TextStyle(
                        fontSize: compact ? 14 : 17,
                        height: 1.25,
                        fontWeight:
                            compact ? FontWeight.w600 : FontWeight.w700,
                      ).c(context.colors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The home screen's news card (1.4.0): as wide as the Community cards, a
/// 16:9 crop of the cover centred on the photo, the "Öne çıkan" chip on it,
/// then the date and the title (two lines at most).
class HomeNewsCard extends StatelessWidget {
  const HomeNewsCard({super.key, required this.item, required this.onTap});

  static const photoAspect = 16 / 9;
  static const _textPadding = EdgeInsets.fromLTRB(16, 12, 16, 14);
  static const _dateStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  static const _titleStyle =
      TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w700);

  final MosqueNews item;
  final VoidCallback onTap;

  /// The card's height at [width] with a two-line title, for a row of cards
  /// that must all be as tall (the home rail). Follows the text size.
  static double heightFor(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    // The app's own text style underneath, so the font and its line height
    // are the ones the card draws with.
    final base = DefaultTextStyle.of(context).style;
    double lines(TextStyle style, String text, int max) => (TextPainter(
          text: TextSpan(text: text, style: base.merge(style)),
          maxLines: max,
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout())
            .height;
    return width / photoAspect +
        _textPadding.vertical +
        lines(_dateStyle, '0', 1) +
        3 +
        lines(_titleStyle, '0\n0', 2) +
        1; // rounding
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: context.shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  NewsPhotoFrame(
                    photo: item.cover,
                    fallbackLabel: item.title,
                    aspectRatio: photoAspect,
                    alwaysCover: true,
                  ),
                  if (item.featured)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Pill(
                        label: l.newsFeatured,
                        fill: context.colors.goldBg,
                        ink: context.colors.goldText,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: _textPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsDay(l, item.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dateStyle.c(context.colors.ink3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle.c(context.colors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fill, required this.ink});

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700).c(ink),
      ),
    );
  }
}
