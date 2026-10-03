import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Cross-fades when [child]'s key (or type) changes, so content arriving —
/// data replacing a shimmer, one stage replacing another — never snaps.
/// Give each state its own `ValueKey`.
///
/// With [animateSize] the height eases to the new content as well; leave it
/// off for long lists, where the jump is cheaper than the relayout.
class FadeSwitch extends StatelessWidget {
  const FadeSwitch({
    super.key,
    required this.child,
    this.duration = AppMotion.base,
    this.alignment = AlignmentDirectional.topStart,
    this.animateSize = false,
  });

  final Widget child;
  final Duration duration;
  final AlignmentDirectional alignment;
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    Widget switcher = AnimatedSwitcher(
      duration: AppMotion.fade(context, duration),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.exit,
      // Passthrough: each child is laid out exactly as it would be without
      // the switcher (full width in a list, stretched in a card).
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        fit: StackFit.passthrough,
        children: [...previous, ?current],
      ),
      child: child,
    );
    if (animateSize) {
      switcher = AnimatedSize(
        duration: AppMotion.move(context, duration),
        curve: AppMotion.standard,
        alignment: alignment,
        child: switcher,
      );
    }
    return switcher;
  }
}

/// How a [Pressable] answers a finger: [dim] for buttons and cards, [highlight]
/// for list rows (the grey wash of an iOS table cell).
enum PressEffect { dim, highlight }

/// The iOS press: the effect lands the instant the finger is down and eases
/// off over [AppMotion.fast] when it lifts.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.effect = PressEffect.dim,
    this.pressedOpacity = 0.75,
  });

  final Widget child;
  final VoidCallback? onTap;
  final PressEffect effect;

  /// Opacity while held, for [PressEffect.dim].
  final double pressedOpacity;

  static const _highlight = Color(0x0F0F1C17);

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final duration = _down ? Duration.zero : AppMotion.fast;
    final Widget body = switch (widget.effect) {
      PressEffect.dim => AnimatedOpacity(
          opacity: _down ? widget.pressedOpacity : 1,
          duration: duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      PressEffect.highlight => Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _down ? 1 : 0,
                  duration: duration,
                  curve: Curves.easeOut,
                  child: const ColoredBox(color: Pressable._highlight),
                ),
              ),
            ),
          ],
        ),
    };
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
