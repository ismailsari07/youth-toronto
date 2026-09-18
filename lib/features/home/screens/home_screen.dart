import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models.dart';
import '../../../core/prayer_utils.dart';
import '../../../core/theme.dart';
import '../../../shared/providers/prayer_provider.dart';

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

  static int _calcSecondsFromNow(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
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

    final now = DateTime.now();
    final prevParts = filtered[nextIdx - 1].time.split(':');
    final nextParts = nextPrayer.time.split(':');

    var prevTime = DateTime(
      now.year, now.month, now.day,
      int.parse(prevParts[0]), int.parse(prevParts[1]),
    );
    var nextTime = DateTime(
      now.year, now.month, now.day,
      int.parse(nextParts[0]), int.parse(nextParts[1]),
    );

    if (!nextTime.isAfter(prevTime)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }
    if (prevTime.isAfter(now)) {
      prevTime = prevTime.subtract(const Duration(days: 1));
    }

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
    final prayerAsync = ref.watch(prayerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: prayerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load', style: AppTextStyles.body),
        ),
        data: (payload) {
          if (payload == null) {
            return Center(
              child: Text('No data available', style: AppTextStyles.body),
            );
          }
          final nextPrayer = getNextPrayer(payload.dailyPrayerTimes);
          final secondsLeft = _calcSecondsFromNow(nextPrayer.time);
          final progress = _calcProgress(payload.dailyPrayerTimes, nextPrayer);
          return _buildBody(payload, nextPrayer, secondsLeft, progress);
        },
      ),
    );
  }

  Widget _buildBody(
    PrayerCachePayload payload,
    NextPrayer nextPrayer,
    int secondsLeft,
    double progress,
  ) {
    return SafeArea(
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
            _animate(3, _buildNextPrayerCard(nextPrayer, secondsLeft, progress)),
            const SizedBox(height: 12),
            _animate(4, _buildPrayerStrip(payload.dailyPrayerTimes, nextPrayer)),
            const SizedBox(height: 28),
            _animate(5, _buildSectionHeader('UPCOMING', 'Events')),
            const SizedBox(height: 12),
            _animate(5, _buildEventsRow()),
            const SizedBox(height: 28),
            _animate(6, _buildSectionHeader('LATEST', 'Announcement')),
            const SizedBox(height: 12),
            _animate(6, _buildAnnouncementCard()),
            const SizedBox(height: 32),
            _animate(6, _buildOrnamentDivider()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '◈',
              style: TextStyle(color: AppColors.gold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              'M Y T',
              style: GoogleFonts.dmSans(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textMuted, width: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textMuted,
            size: 18,
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

  Widget _buildSectionHeader(String label, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            Text('See all →', style: AppTextStyles.goldAccent),
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

  Widget _buildEventsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventCard(
            title: 'Youth Iftar',
            date: 'Apr 15 · 8:15 PM',
            isFree: true,
          ),
          const SizedBox(width: 12),
          _buildEventCard(
            title: 'Tafsir Circle',
            date: 'May 8 · 7:30 PM',
            isFree: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required bool isFree,
  }) {
    return Container(
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
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceElevated, AppColors.surface],
                    ),
                  ),
                  child: Center(
                    child: Text('EVENT IMAGE', style: AppTextStyles.label),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: AppColors.gold),
                ),
                if (isFree)
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
                        'FREE',
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
                  title,
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
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
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Text(
                '2 days ago',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'New Prayer Hall Opens',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Our new prayer hall at the North York branch opened with "
            "this Friday's jummah. All are warmly invited.",
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
    );
  }
}
