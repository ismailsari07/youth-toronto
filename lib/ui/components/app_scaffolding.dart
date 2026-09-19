import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_icon.dart';
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
        gradient: heroGradient,
        color: AppColor.heroBase,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadow.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heroTitle.c(AppColor.onHero)),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColor.heroDivider),
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
          decoration: const BoxDecoration(
            color: AppColor.heroCircleBg,
            shape: BoxShape.circle,
          ),
          child: AppIcon(icon, size: iconSize, color: AppColor.onHero),
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
                        .c(AppColor.onHero),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.countdownSub.c(AppColor.onHeroSecondary),
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
              shadow: AppShadow.floatingButton,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(height: 16),
          Text(eyebrow, style: AppText.eyebrow.c(AppColor.green)),
          const SizedBox(height: 4),
          Text(title, style: AppText.screenTitle.c(AppColor.ink)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)
                  .c(AppColor.ink2),
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
                  decoration: const BoxDecoration(
                    color: AppColor.greenTint,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(icon, size: 32, color: AppColor.green),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ).c(AppColor.ink),
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
                    ).c(AppColor.ink2),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColor.hairline),
          AppListRow(
            icon: AppIcons.bell,
            title: AppStrings.notifyMe,
            titleStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)
                .c(AppColor.ink),
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
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  static const _from = Color(0xFFE8EDEB);
  static const _to = Color(0xFFF4F7F6);

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
          color: Color.lerp(_from, _to, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
