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
