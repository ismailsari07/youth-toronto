import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'app_controls.dart';
import 'app_row.dart';

/// Spec §4.7. The gradient card at the top of each tab root. It always carries
/// live content in [row] — a green band with only a title is decoration.
class GradientTabHeader extends StatelessWidget {
  const GradientTabHeader({
    super.key,
    required this.title,
    required this.row,
    this.footer,
  });

  final String title;
  final Widget row;

  /// Extra content inside the card, below the row — e.g. the signed-out
  /// sign in / create account buttons, which must sit on the gradient.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: context.colors.heroGradient,
        color: context.colors.heroBase,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: context.shadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heroTitle.c(context.colors.onHero)),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: context.colors.heroDivider),
          const SizedBox(height: 14),
          row,
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

/// The live row inside a gradient header: circle, title + subtitle, optional
/// trailing badge or button.
class HeroRow extends StatelessWidget {
  const HeroRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.circleSize = 42,
    this.iconSize = 21,
    this.titleStyle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double circleSize;
  final double iconSize;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Row(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.heroCircleBg,
            shape: BoxShape.circle,
          ),
          child: AppIcon(icon, size: iconSize, color: context.colors.onHero),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: titleStyle ??
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)
                        .c(context.colors.onHero),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.countdownSub.c(context.colors.onHeroSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Spec §4.8. Every pushed screen: light ground, round white back button,
/// eyebrow, large title, optional subtitle.
class PlainNavBar extends StatelessWidget {
  const PlainNavBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-4, 0),
            child: CircleIconButton(
              icon: AppIcons.chevronLeft,
              size: 44,
              iconSize: 20,
              bordered: false,
              shadow: context.shadows.floatingButton,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(height: 16),
          Text(eyebrow, style: AppText.eyebrow.c(context.colors.green)),
          const SizedBox(height: 4),
          Text(title, style: AppText.screenTitle.c(context.colors.ink)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)
                  .c(context.colors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spec §4.9. Not an apology — a card that still does something: the working
/// notification row stays at the bottom.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.notifyValue = true,
    this.onNotifyChanged,
  });

  final String icon;
  final String title;
  final String body;
  final bool notifyValue;
  final ValueChanged<bool>? onNotifyChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      grouped: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.greenTint,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(icon, size: 32, color: context.colors.green),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ).c(context.colors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 258),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ).c(context.colors.ink2),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.colors.hairline),
          AppListRow(
            icon: AppIcons.bell,
            title: context.l10n.notifyMe,
            titleStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)
                .c(context.colors.ink),
            trailing: AppSwitch(value: notifyValue, onChanged: onNotifyChanged),
          ),
        ],
      ),
    );
  }
}

/// Spec §7.1b / §7.15. Shimmer, never spinners, for anything with a known
/// shape: #E8EDEB → #F4F7F6 over 1.2s.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.onDark = false,
  });

  final double width;
  final double height;
  final double radius;

  /// Pale grey reads as a bright block on the navy moon card; on dark
  /// surfaces the block is a low-opacity white instead.
  final bool onDark;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: the block holds still, halfway between its two shades.
    if (AppMotion.reduced(context)) {
      _c
        ..stop()
        ..value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.onDark
              ? Color.lerp(context.colors.heroShimmerFrom, context.colors.heroShimmerTo, _c.value)
              : Color.lerp(context.colors.shimmerFrom, context.colors.shimmerTo, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Spec §7.6: the sticky action bar on pushed screens. White at 82% with a
/// 22-sigma blur and a hairline top border.
class StickyBottomBar extends StatelessWidget {
  const StickyBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.barBg,
            border: Border(top: BorderSide(color: context.colors.barBorder)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
