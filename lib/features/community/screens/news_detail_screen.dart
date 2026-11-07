import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/news/mosque_news.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/news_photo.dart';

/// A news item: the gallery full width on top (swipe, dots; tap for
/// full-screen with pinch to zoom), then the date, the title and the text.
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.item});

  final MosqueNews item;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final item = widget.item;
    try {
      await SharePlus.instance.share(
        ShareParams(text: '${item.title}\n\n${item.body}', subject: item.title),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  List<String> get _paragraphs => widget.item.body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final slides = item.slides;
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: NewsPhotoFrame.defaultAspectRatio,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Semantics(
                    button: true,
                    label: l.newsOpenPhoto('${i + 1}', '${slides.length}'),
                    child: GestureDetector(
                      onTap: () => showNewsViewer(
                        context,
                        photos: slides,
                        start: i,
                        title: item.title,
                        onPageChanged: (page) {
                          if (_pages.hasClients) _pages.jumpToPage(page);
                        },
                      ),
                      child: NewsPhotoFrame(
                        photo: slides[i],
                        fallbackLabel: item.title,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: top + 8,
                child: _RoundButton(
                  icon: AppIcons.chevronLeft,
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Positioned(
                right: 12,
                top: top + 8,
                child: _RoundButton(
                  icon: AppIcons.share,
                  label: l.newsShare,
                  onTap: _share,
                ),
              ),
            ],
          ),
          if (slides.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(
                label: '${_index + 1} / ${slides.length}',
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? context.colors.green
                              : context.colors.ink3.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.pageGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsDay(l, item.date),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                      .c(context.colors.goldText),
                ),
                const SizedBox(height: 8),
                Text(item.title, style: AppText.screenTitle.c(context.colors.ink)),
                const SizedBox(height: 10),
                for (final paragraph in _paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      paragraph,
                      style: AppText.bodyLarge.c(context.colors.ink2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// On a photo, so the same in light and dark.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x9E0A1310),
            shape: BoxShape.circle,
          ),
          child: AppIcon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
