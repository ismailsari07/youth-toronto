import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Carries the active tab's entrance animation down to its sections. Absent
/// (pushed screens, tests), sections simply show.
class TabEntrance extends InheritedWidget {
  const TabEntrance({super.key, required this.animation, required super.child});

  /// 0 → 1 over [AppMotion.staggerTotal] each time the tab becomes active.
  final Animation<double> animation;

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabEntrance>()?.animation ??
      kAlwaysCompleteAnimation;

  @override
  bool updateShouldNotify(TabEntrance old) => old.animation != animation;
}

/// One section of a tab root in the entrance cascade: a light fade and a
/// [AppMotion.staggerRise] px rise, starting [AppMotion.staggerStep] × [index]
/// into the entrance (capped to fit [AppMotion.staggerTotal]).
class StaggerItem extends StatelessWidget {
  const StaggerItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = AppMotion.staggerTotal.inMilliseconds;
    final item = AppMotion.staggerItem.inMilliseconds;
    final start = (AppMotion.staggerStep.inMilliseconds * index)
        .clamp(0, total - item);
    final progress = CurvedAnimation(
      parent: TabEntrance.of(context),
      curve: Interval(
        start / total,
        (start + item) / total,
        curve: AppMotion.standard,
      ),
    );
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (_, child) {
        final t = progress.value;
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, AppMotion.staggerRise * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
