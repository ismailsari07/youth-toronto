import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models.dart';
import '../../../core/theme.dart';
import '../../../shared/providers/events_news_provider.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

String _fmtTimestamp(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 28) return '${(diff.inDays / 7).floor()} weeks ago';
  return '${(diff.inDays / 30).floor()} months ago';
}

// ─── Stagger constants ────────────────────────────────────────────────────────

const _kItemCount = 2;
const _kDelayMs = 25;
const _kDurationMs = 150;
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── News Screen ──────────────────────────────────────────────────────────────

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnims;
  late final List<Animation<double>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    );

    _opacityAnims = List.generate(_kItemCount, (i) {
      final begin = (i * _kDelayMs) / _kTotalMs;
      final end = (i * _kDelayMs + _kDurationMs) / _kTotalMs;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_kItemCount, (i) {
      final begin = (i * _kDelayMs) / _kTotalMs;
      final end = (i * _kDelayMs + _kDurationMs) / _kTotalMs;
      return Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animate(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, widget) => Opacity(
        opacity: _opacityAnims[index].value,
        child: Transform.translate(
          offset: Offset(0, _slideAnims[index].value),
          child: widget,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animate(0, _buildHeader()),
            Expanded(
              child: _animate(
                1,
                newsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      const Center(child: Text('Failed to load news')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('No announcements'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, index) => const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, i) =>
                          _buildNewsItem(context, items[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNITY', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'Announcements',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(BuildContext context, NewsItem item) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => _NewsDetailScreen(item: item),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBadge(item.isNew),
                const Spacer(),
                Text(
                  _fmtTimestamp(item.createdAt),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.teaser,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text('READ →', style: AppTextStyles.goldAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(bool isNew) {
    if (isNew) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('NEW', style: AppTextStyles.goldAccent.copyWith(fontSize: 10)),
        ],
      );
    }
    return Text(
      '—',
      style: AppTextStyles.body.copyWith(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────────

class _NewsDetailScreen extends StatelessWidget {
  const _NewsDetailScreen({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ANNOUNCEMENT', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmtTimestamp(item.createdAt),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCoverImage(),
                    const SizedBox(height: 24),
                    Text(
                      item.body,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
          _buildIconButton(icon: Icons.ios_share_outlined),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildCoverImage() {
    final url = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: url != null
            ? Image.network(url, fit: BoxFit.cover, width: double.infinity)
            : Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _HatchPainter()),
                  const Center(
                    child: Text(
                      'COVER IMAGE',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'MYT',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              letterSpacing: 2,
            ),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
      ],
    );
  }
}

// ─── Hatch Painter ────────────────────────────────────────────────────────────

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.surface,
    );
    final linePaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    const spacing = 18.0;
    for (double d = -size.height; d <= size.width; d += spacing) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
