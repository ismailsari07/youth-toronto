import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/models.dart';
import '../../../core/prayer_utils.dart';
import '../../../core/theme.dart';
import '../../../shared/providers/prayer_provider.dart';

const _arabicNames = <String, String>{
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

const _hijriMonths = [
  '',
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  "Jumada al-Awwal",
  "Jumada al-Thani",
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  "Dhu al-Hijjah",
];

// ─── Stagger constants ────────────────────────────────────────────────────────

const _kItemCount = 7;
const _kDelayMs = 25;
const _kDurationMs = 150;
// Total = (itemCount - 1) * delay + duration = 6*60 + 300 = 660ms
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── Screen ───────────────────────────────────────────────────────────────────

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen>
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
    final prayerAsync = ref.watch(prayerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: prayerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load prayer times', style: AppTextStyles.body),
        ),
        data: (payload) {
          if (payload == null) {
            return Center(
              child: Text('No data available', style: AppTextStyles.body),
            );
          }
          final nextPrayer = getNextPrayer(payload.dailyPrayerTimes);
          return _buildBody(payload, nextPrayer);
        },
      ),
    );
  }

  Widget _buildBody(PrayerCachePayload payload, NextPrayer nextPrayer) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _animate(0, _buildHeader()),
            const SizedBox(height: 16),
            _animate(1, _buildChips(payload)),
            const SizedBox(height: 16),
            _animate(2, _buildSegmentedControl()),
            const SizedBox(height: 12),
            _animate(3, _buildDateNav(payload.gregorianDate)),
            const SizedBox(height: 16),
            _animate(4, _buildPrayerCard(payload.dailyPrayerTimes, nextPrayer)),
            if (payload.jumaaPrayerTime != null) ...[
              const SizedBox(height: 12),
              _animate(5, _buildJumaaCard(payload.jumaaPrayerTime!)),
            ],
            const SizedBox(height: 32),
            _animate(6, _buildFooter()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIMES', style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text('Prayer Times', style: AppTextStyles.heading),
      ],
    );
  }

  Widget _buildChips(PrayerCachePayload payload) {
    return Row(
      children: [
        _buildPill(
          borderColor: AppColors.gold,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppColors.gold, size: 14),
              const SizedBox(width: 4),
              Text(
                'Toronto, ON',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildPill(
          borderColor: const Color(0x665A5F52),
          child: Text(
            _formatHijriDate(payload.hijriDate),
            style: AppTextStyles.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({required Color borderColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegment('Daily', isActive: true)),
          Expanded(child: _buildSegment('Monthly', isActive: false)),
          Expanded(child: _buildSegment('Yearly', isActive: false)),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isActive
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gold, width: 1),
            )
          : null,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDateNav(String gregorianDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 20),
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatGregorianDate(gregorianDate),
                  style: AppTextStyles.body.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'TODAY',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(List<DailyPrayerItem> prayers, NextPrayer nextPrayer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < prayers.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.background,
              ),
            _buildPrayerRow(
              prayers[i],
              isHighlighted: nextPrayer.name == prayers[i].name,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow(
    DailyPrayerItem prayer, {
    required bool isHighlighted,
  }) {
    final arabic = _arabicNames[prayer.name] ?? '';
    final isSunrise = prayer.name == 'Sunrise';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isHighlighted ? AppColors.surfaceHighlight : AppColors.surface,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabic,
                style: AppTextStyles.label.copyWith(fontSize: 11),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                prayer.name,
                style: AppTextStyles.body.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                prayer.time,
                style: GoogleFonts.cormorantGaramond(
                  fontStyle: FontStyle.italic,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color:
                      isHighlighted ? AppColors.gold : AppColors.textPrimary,
                ),
              ),
              if (prayer.iqamah != null)
                Text(
                  prayer.iqamah!,
                  style: AppTextStyles.label.copyWith(fontSize: 11),
                ),
            ],
          ),
          const SizedBox(width: 12),
          if (!isSunrise)
            Icon(
              isHighlighted ? Icons.notifications : Icons.notifications_none,
              color: isHighlighted ? AppColors.gold : AppColors.textMuted,
              size: 20,
            )
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildJumaaCard(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الجمعة',
                style: AppTextStyles.label.copyWith(fontSize: 11),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                "Jumu'ah",
                style: AppTextStyles.body.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            time,
            style: GoogleFonts.cormorantGaramond(
              fontStyle: FontStyle.italic,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 0.5,
                color: Color(0x335A5F52),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '◆',
                style: TextStyle(color: AppColors.textMuted, fontSize: 8),
              ),
            ),
            Expanded(
              child: Divider(
                thickness: 0.5,
                color: Color(0x335A5F52),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'SOURCE · DIYANET CALENDAR',
            style: AppTextStyles.label,
          ),
        ),
      ],
    );
  }

  static String _formatGregorianDate(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length != 3) return dateStr;
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return DateFormat('EEEE, MMMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatHijriDate(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length != 3) return dateStr;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final monthName =
          (month >= 1 && month <= 12) ? _hijriMonths[month] : '';
      return '$day $monthName $year';
    } catch (_) {
      return dateStr;
    }
  }
}
