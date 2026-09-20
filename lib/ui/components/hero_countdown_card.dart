import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/prayer_utils.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'countdown_arc.dart';

/// Spec §6 — the signature element. Digits tick every second; the arc sweep
/// only updates once a minute (redrawing it per tick is wasteful and visibly
/// stutters) and animates over 600ms at rollover.
class HeroCountdownCard extends StatefulWidget {
  const HeroCountdownCard({super.key, required this.prayers});

  /// Null while loading; empty-handed when prayer times cannot be loaded.
  final List<DailyPrayerItem>? prayers;

  @override
  State<HeroCountdownCard> createState() => _HeroCountdownCardState();
}

class _HeroCountdownCardState extends State<HeroCountdownCard> {
  Timer? _tick;
  PrayerWindow? _window;
  double _sweep = 0;
  int _sweepMinute = -1;

  @override
  void initState() {
    super.initState();
    _refresh();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didUpdateWidget(HeroCountdownCard old) {
    super.didUpdateWidget(old);
    if (old.prayers != widget.prayers) _refresh();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _refresh() {
    final prayers = widget.prayers;
    final window = prayers == null ? null : currentPrayerWindow(prayers);
    final minute = DateTime.now().minute;
    setState(() {
      _window = window;
      if (window != null && minute != _sweepMinute) {
        _sweepMinute = minute;
        _sweep = window.progress;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final window = _window;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: heroGradient,
        color: AppColor.heroBase,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadow.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topRow(),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              // Derived from the arc, so the box can never be shorter than
              // what the painter draws (spec §6's 180 stack at design size).
              height: CountdownArc.stackHeight(constraints.maxWidth),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _sweep, end: _sweep),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (_, value, _) => CountdownArc(progress: value),
                    ),
                  ),
                  Positioned(
                    top: 74,
                    left: 0,
                    right: 0,
                    child: _centreText(window),
                  ),
                ],
              ),
            ),
          ),
          _bottomRow(window),
        ],
      ),
    );
  }

  Widget _topRow() {
    return SizedBox(
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 26,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColor.heroPillBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'NEXT PRAYER',
              style: AppText.badge
                  .copyWith(letterSpacing: 1.1)
                  .c(AppColor.onHero),
            ),
          ),
          Container(
            height: 26,
            padding: const EdgeInsets.only(left: 8, right: 11),
            decoration: BoxDecoration(
              color: AppColor.heroChipBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(AppIcons.pin, size: 13, color: AppColor.onHeroChipText),
                const SizedBox(width: 5),
                Text(
                  'Toronto',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)
                      .c(AppColor.onHeroChipText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centreText(PrayerWindow? window) {
    if (window == null) {
      // Spec §7.1c — times unavailable: the card still renders, arc at 0.
      return Column(
        children: [
          Text(
            'Times unavailable',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)
                .c(AppColor.onHero),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull to refresh',
            style: AppText.countdownSub.c(AppColor.onHeroSecondary),
          ),
        ],
      );
    }

    final next = window.next;
    final seconds = window.secondsToNext;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final digits = '$h:${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          next.name.toUpperCase(),
          style: AppText.countdownLabel.c(AppColor.onHeroLabel),
        ),
        const SizedBox(height: 2),
        Text(digits, style: AppText.countdown.c(AppColor.onHero)),
        const SizedBox(height: 2),
        Text(
          'Athan ${prayerClock12(next.name, next.time)}'
          '${next.iqamah == null ? '' : ' · Iqamah ${prayerClock12(next.name, next.iqamah!)}'}',
          style: AppText.countdownSub.c(AppColor.onHeroSecondary),
        ),
      ],
    );
  }

  Widget _bottomRow(PrayerWindow? window) {
    if (window == null) return const SizedBox(height: 4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _edgeLabel(
          '${window.current.name} · now',
          prayerClock12(window.current.name, window.current.time),
          CrossAxisAlignment.start,
        ),
        _edgeLabel(
          window.next.name,
          prayerClock12(window.next.name, window.next.time),
          CrossAxisAlignment.end,
        ),
      ],
    );
  }

  Widget _edgeLabel(String title, String time, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)
              .c(AppColor.onHero),
        ),
        const SizedBox(height: 1),
        Text(
          time,
          style: const TextStyle(fontSize: 11.5).c(AppColor.onHeroSecondary),
        ),
      ],
    );
  }
}
