import 'package:flutter/material.dart';

/// Motion tokens. Short, ease-out, never bouncy; nothing an element does on
/// its own runs past 350 ms. Page pushes keep the native iOS 500 ms slide.
///
/// Reduce Motion (`MediaQuery.disableAnimations`): movement — slides, sizes,
/// the tab fade, sheets — becomes instant; content cross-fades stay, shorter,
/// because a fade is what iOS itself substitutes for motion.
abstract final class AppMotion {
  /// Tab switches, press release, small colour changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// Content arriving: data replacing a shimmer, a stage changing.
  static const Duration base = Duration(milliseconds: 250);

  /// Bottom sheets rising; they leave in [base].
  static const Duration sheet = Duration(milliseconds: 350);

  /// The standard ease-out for anything arriving.
  static const Curve standard = Curves.easeOutCubic;

  /// For what is leaving: quick, so it never lingers under what arrives.
  static const Curve exit = Curves.easeInCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duration for something that moves or resizes: zero under Reduce Motion.
  static Duration move(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// Duration for a cross-fade: kept under Reduce Motion, but short.
  static Duration fade(BuildContext context, Duration d) =>
      reduced(context) && d > fast ? fast : d;
}

/// Every push slides the iOS way, on every platform, with the edge swipe back.
/// Under Reduce Motion the slide becomes a cross-fade, as on iOS; the back
/// swipe still works and drives the fade.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const _slide = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => _slide.transitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        bool allowSnapshotting,
        Widget? child,
      ) =>
          AppMotion.reduced(context)
              ? child ?? const SizedBox.shrink()
              : _slide.delegatedTransition!(
                  context,
                  animation,
                  secondaryAnimation,
                  allowSnapshotting,
                  child,
                );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!AppMotion.reduced(context)) {
      return _slide.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // The slide is held at rest (complete, no parallax) so only its back
    // gesture remains; the gesture moves the route's own animation, which
    // the fade follows.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
      child: _slide.buildTransitions(
        route,
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      ),
    );
  }
}
