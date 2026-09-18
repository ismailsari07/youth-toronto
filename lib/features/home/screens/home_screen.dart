import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../core/prayer_utils.dart';
import '../../../core/theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/events_news_provider.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../events/screens/events_screen.dart';
import '../../news/screens/news_screen.dart';

const _stripAbbrev = <String, String>{
  'Fajr': 'FAJR',
  'Dhuhr': 'DHUH',
  'Asr': 'ASR',
  'Maghrib': 'MAGH',
  'Isha': 'ISHA',
};

const _arabicNames = <String, String>{
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

enum _StripStatus { past, active, future }

// ─── Stagger constants ────────────────────────────────────────────────────────

const _kItemCount = 7;
const _kDelayMs = 25;
const _kDurationMs = 150;
// Total = (itemCount - 1) * delay + duration = 6*60 + 300 = 660ms
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnims;
  late final List<Animation<double>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });

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
    _timer?.cancel();
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

  // Countdown and progress run on the mosque's clock (see mosque_time.dart),
  // so they're right for any device time zone and for 12-hour stored times.

  static int _calcSecondsFromNow(NextPrayer nextPrayer) {
    final now = mosqueNow();
    final today = DateTime(now.year, now.month, now.day);
    var target = prayerMoment(today, nextPrayer.name, nextPrayer.time);
    if (target == null) return 0;
    if (!target.isAfter(now)) {
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      target = prayerMoment(tomorrow, nextPrayer.name, nextPrayer.time)!;
    }
    return target.difference(now).inSeconds;
  }

  static double _calcProgress(
    List<DailyPrayerItem> prayers,
    NextPrayer nextPrayer,
  ) {
    final filtered = prayers.where((p) => p.name != 'Sunrise').toList();
    final nextIdx = filtered.indexWhere((p) => p.name == nextPrayer.name);
    if (nextIdx <= 0) return 0.0;

    final now = mosqueNow();
    final today = DateTime(now.year, now.month, now.day);
    final prev = filtered[nextIdx - 1];
    final prevTime = prayerMoment(today, prev.name, prev.time);
    final nextTime = prayerMoment(today, nextPrayer.name, nextPrayer.time);
    if (prevTime == null || nextTime == null) return 0.0;

    final total = nextTime.difference(prevTime).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = now.difference(prevTime).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  static String _formatCountdown(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Sections load independently: missing prayer data must not blank Home.
    final prayerAsync = ref.watch(prayerProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _animate(0, _buildHeader()),
              const SizedBox(height: 24),
              _animate(1, _buildGreeting()),
              const SizedBox(height: 20),
              _animate(2, _buildOrnamentDivider()),
              const SizedBox(height: 20),
              ..._buildPrayerSection(prayerAsync),
              ..._buildEventsSection(eventsAsync),
              ..._buildAnnouncementSection(newsAsync),
              const SizedBox(height: 32),
              _animate(6, _buildOrnamentDivider()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrayerSection(AsyncValue<PrayerCachePayload?> async) {
    final payload = async.valueOrNull;
    if (async.isLoading && payload == null) {
      return [_sectionSpinner(height: 180)];
    }
    if (payload == null) {
      return [
        _animate(
          3,
          _buildMessageCard('Prayer times unavailable right now'),
        ),
      ];
    }
    final nextPrayer = getNextPrayer(payload.dailyPrayerTimes);
    final secondsLeft = _calcSecondsFromNow(nextPrayer);
    final progress = _calcProgress(payload.dailyPrayerTimes, nextPrayer);
    return [
      _animate(3, _buildNextPrayerCard(nextPrayer, secondsLeft, progress)),
      const SizedBox(height: 12),
      _animate(4, _buildPrayerStrip(payload.dailyPrayerTimes, nextPrayer)),
    ];
  }

  List<Widget> _buildEventsSection(AsyncValue<List<YouthEvent>> async) {
    if (async.isLoading && !async.hasValue) {
      return [const SizedBox(height: 28), _sectionSpinner(height: 130)];
    }
    // eventsProvider already returns upcoming events only.
    final upcoming =
        (async.valueOrNull ?? const <YouthEvent>[]).take(3).toList();
    if (upcoming.isEmpty) return const [];
    return [
      const SizedBox(height: 28),
      _animate(
        5,
        _buildSectionHeader(
          'UPCOMING',
          'Events',
          onSeeAll: () => context.go('/events'),
        ),
      ),
      const SizedBox(height: 12),
      _animate(5, _buildEventsRow(upcoming)),
    ];
  }

  List<Widget> _buildAnnouncementSection(
    AsyncValue<List<Announcement>> async,
  ) {
    if (async.isLoading && !async.hasValue) {
      return [const SizedBox(height: 28), _sectionSpinner(height: 130)];
    }
    final items = async.valueOrNull ?? const <Announcement>[];
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 28),
      _animate(
        6,
        _buildSectionHeader(
          'LATEST',
          'Announcement',
          onSeeAll: () => context.go('/news'),
        ),
      ),
      const SizedBox(height: 12),
      _animate(6, _buildAnnouncementCard(items.first)),
    ];
  }

  Widget _sectionSpinner({required double height}) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '◈',
          style: TextStyle(color: AppColors.gold, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          'PAPE MOSQUE',
          style: GoogleFonts.dmSans(
            color: AppColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum',
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Peace be upon you.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOrnamentDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '◈',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
      ],
    );
  }

  Widget _buildNextPrayerCard(
    NextPrayer nextPrayer,
    int secondsLeft,
    double progress,
  ) {
    final arabic = _arabicNames[nextPrayer.name] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Next Prayer', style: AppTextStyles.label),
                    Text('Adhan', style: AppTextStyles.label),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextPrayer.name,
                          style: GoogleFonts.cormorantGaramond(
                            color: AppColors.textPrimary,
                            fontSize: 38,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          arabic,
                          style: AppTextStyles.label.copyWith(fontSize: 11),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      nextPrayer.time,
                      style: GoogleFonts.cormorantGaramond(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.cardBorder,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TIME REMAINING', style: AppTextStyles.label),
                    Text(
                      _formatCountdown(secondsLeft),
                      style: GoogleFonts.dmSans(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(
                  height: 3,
                  width: double.infinity,
                  color: AppColors.surfaceElevated,
                ),
                Container(
                  height: 3,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerStrip(
    List<DailyPrayerItem> prayers,
    NextPrayer nextPrayer,
  ) {
    final filtered = prayers.where((p) => p.name != 'Sunrise').toList();
    final nextIdx = filtered.indexWhere((p) => p.name == nextPrayer.name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < filtered.length; i++)
            _buildStripColumn(
              filtered[i],
              status: i < nextIdx
                  ? _StripStatus.past
                  : i == nextIdx
                      ? _StripStatus.active
                      : _StripStatus.future,
            ),
        ],
      ),
    );
  }

  Widget _buildStripColumn(
    DailyPrayerItem prayer, {
    required _StripStatus status,
  }) {
    final abbrev = _stripAbbrev[prayer.name] ?? prayer.name;
    final isActive = status == _StripStatus.active;

    final col = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(abbrev, style: AppTextStyles.label.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        isActive
            ? Text(
                prayer.time,
                style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Text(
                prayer.time,
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );

    return status == _StripStatus.past
        ? Opacity(opacity: 0.4, child: col)
        : col;
  }

  Widget _buildSectionHeader(
    String label,
    String title, {
    required VoidCallback onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
                child: Text('See all →', style: AppTextStyles.goldAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _openRoute(Widget screen) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _buildEventsRow(List<YouthEvent> events) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < events.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _buildEventCard(events[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildEventImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
      ),
    );
  }

  Widget _buildEventCard(YouthEvent event) {
    final imageUrl = event.imageUrl;
    return GestureDetector(
      onTap: () => _openRoute(EventDetailScreen(event: event)),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildEventImageFallback(),
                    )
                  else
                    _buildEventImageFallback(),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: AppColors.gold),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textMuted,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        event.isFree ? 'FREE' : (event.price ?? 'PAID'),
                        style: AppTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eventCardDate(event.dateTime),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement item) {
    return GestureDetector(
      onTap: () => _openRoute(NewsDetailScreen(item: item)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold, width: 0.8),
                    ),
                    child: Text('NEW', style: AppTextStyles.goldAccent),
                  ),
                const Spacer(),
                Text(
                  timeAgo(item.date),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text('READ MORE →', style: AppTextStyles.goldAccent),
            ),
          ],
        ),
      ),
    );
  }
}
