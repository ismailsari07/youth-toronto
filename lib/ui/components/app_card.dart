import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'motion.dart';

/// Spec §4.1. A white card with the two-layer card shadow. [grouped] clips
/// children so row backgrounds follow the corner radius.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.padding,
    this.grouped = false,
    this.color = AppColor.card,
    this.border,
    this.shadow = AppShadow.card,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool grouped;
  final Color color;
  final BoxBorder? border;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: grouped ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Section header (spec §7.1 step 3): title on the left, an optional trailing
/// label or "See all" action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.onTrailingTap,
  });

  final String title;
  final String? trailingText;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final trailing = trailingText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: AppText.sectionHeader.c(AppColor.ink)),
        if (trailing != null)
          if (onTrailingTap != null)
            Pressable(
              onTap: onTrailingTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  trailing,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                      .c(AppColor.green),
                ),
              ),
            )
          else
            Text(
              trailing,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                  .c(AppColor.ink3),
            ),
      ],
    );
  }
}
