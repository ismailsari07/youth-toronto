import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/prayer_utils.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_scaffolding.dart';
import 'moon_countdown.dart';
import 'motion.dart';

/// Spec §6 — the Prayer root's hero. A night-navy card around the moon, whose
/// fill is the elapsed share of the current prayer window.
///
/// Digits tick every second. The card stops that timer when the tab is hidden
/// or the app is backgrounded; the moon's own ripple controller is muted by
/// the same signals (see [_visible]).
class MoonCountdownCard extends StatefulWidget {
  const MoonCountdownCard({super.key, required this.prayers});

  /// Null while loading; empty-handed when prayer times cannot be loaded.
  final List<DailyPrayerItem>? prayers;

  @override
  State<MoonCountdownCard> createState() => _MoonCountdownCardState();
}

class _MoonCountdownCardState extends State<MoonCountdownCard> {
  Timer? _tick;
  AppLifecycleListener? _lifecycle;
  PrayerWindow? _window;

  /// Tab visible *and* app foregrounded. `TickerMode` already mutes the moon
  /// for a hidden tab (go_router wraps inactive branches in one), but a Timer
  /// is not a ticker — it has to be stopped by hand.
  bool _onscreen = true;
  bool _foreground = true;
  bool get _visible => _onscreen && _foreground;

  @override
  void initState() {
    super.initState();
    _read();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final foreground = state == AppLifecycleState.resumed;
        if (foreground == _foreground) return;
        _foreground = foreground;
        _syncTimer();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onscreen = TickerMode.of(context);
    if (onscreen != _onscreen) {
      _onscreen = onscreen;
      // Coming back from a hidden tab, the digits are stale by however long
      // we were away — recompute before resuming the tick.
      if (onscreen) _read();
    }
    _syncTimer();
  }

  @override
  void didUpdateWidget(MoonCountdownCard old) {
    super.didUpdateWidget(old);
    if (old.prayers != widget.prayers) _read();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  void _syncTimer() {
    if (_visible) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => _read());
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _read() {
    final prayers = widget.prayers;
    final window = prayers == null ? null : currentPrayerWindow(prayers);
    if (!mounted) return;
    setState(() => _window = window);
  }

  @override
  Widget build(BuildContext context) {
    final window = _window;
    final loading = widget.prayers == null;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Container(
      // Height is content-driven (≈407); never hard-coded.
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      clipBehavior: Clip.antiAlias, // the halo must not leak past the radius
      decoration: BoxDecoration(
        color: AppColor.night,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadow.night,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topRow(),
          const SizedBox(height: 12),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: window?.progress ?? 0),
              // Spec §6: at rollover the moon drains to empty over 600 ms.
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              builder: (_, value, _) => MoonCountdown(fill: value),
            ),
          ),
          const SizedBox(height: 14),
          // Data arriving, and each prayer rollover, cross-fade rather than
          // snap; the per-second tick keeps its key and simply repaints.
          FadeSwitch(
            alignment: AlignmentDirectional.topCenter,
            child: KeyedSubtree(
              key: ValueKey(
                loading ? 'loading' : window?.next.name ?? 'unavailable',
              ),
              child: loading ? _loadingText() : _text(window),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: AppColor.nightDivider),
          const SizedBox(height: 14),
          FadeSwitch(
            alignment: AlignmentDirectional.topCenter,
            child: KeyedSubtree(
              key: ValueKey(window?.current.name),
              child: _bottomRow(window),
            ),
          ),
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
              color: AppColor.nightPill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              context.l10n.nextPrayer,
              style:
                  AppText.badge.copyWith(letterSpacing: 1.1).c(AppColor.onHero),
            ),
          ),
          Container(
            height: 26,
            padding: const EdgeInsets.only(left: 8, right: 11),
            decoration: BoxDecoration(
              color: AppColor.nightChip,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(AppIcons.pin,
                    size: 13, color: AppColor.onHeroChipText),
                const SizedBox(width: 5),
                Text(
                  context.l10n.city,
                  style:
                      const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)
                          .c(AppColor.onHeroChipText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Spec §7.1b — the shimmer sits where the digits will land; the moon stays
  /// empty and still.
  Widget _loadingText() {
    return const Column(
      children: [
        SizedBox(height: 15),
        SizedBox(height: 2),
        Shimmer(width: 186, height: 46, radius: 10, onDark: true),
        SizedBox(height: 2),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _text(PrayerWindow? window) {
    final l = context.l10n;
    if (window == null) {
      // Spec §7.1c — times unavailable: the card still renders, moon empty.
      return Column(
        children: [
          Text(
            context.l10n.timesUnavailable,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)
                .c(AppColor.onHero),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.pullToRefresh,
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
          upper(prayerLabel(l, next.name), l.localeName),
          style: AppText.countdownLabel.c(AppColor.onHeroLabel),
        ),
        const SizedBox(height: 2),
        Text(digits, style: AppText.countdown.c(AppColor.onHero)),
        const SizedBox(height: 2),
        Text(
          [
            l.athanAt(prayerClock12(next.name, next.time)),
            if (next.iqamah != null)
              l.iqamahAt(prayerClock12(next.name, next.iqamah!)),
          ].join(' · '),
          style: AppText.countdownSub.c(AppColor.onHeroSecondary),
        ),
      ],
    );
  }

  Widget _bottomRow(PrayerWindow? window) {
    if (window == null) return const SizedBox(height: 30);
    final l = context.l10n;
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _edge(
            window.current,
            l.prayerNow(prayerLabel(l, window.current.name)),
            leading: true,
          ),
          _edge(window.next, prayerLabel(l, window.next.name), leading: false),
        ],
      ),
    );
  }

  /// Circle on the outside: left edge leads with it, right edge trails.
  Widget _edge(DailyPrayerItem prayer, String title, {required bool leading}) {
    final circle = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColor.nightChip,
        shape: BoxShape.circle,
      ),
      child: AppIcon(
        AppIcons.forPrayer(prayer.name),
        size: 16,
        color: AppColor.onHero,
      ),
    );
    final label = Column(
      crossAxisAlignment:
          leading ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ).c(AppColor.onHero),
        ),
        Text(
          prayerClock12(prayer.name, prayer.time),
          style: const TextStyle(fontSize: 11.5, height: 1.2)
              .c(AppColor.onHeroSecondary),
        ),
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: leading
          ? [circle, const SizedBox(width: 9), label]
          : [label, const SizedBox(width: 9), circle],
    );
  }
}
