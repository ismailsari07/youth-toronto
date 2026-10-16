import 'package:flutter/material.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'motion.dart';

/// Spec §4.3. All pill-shaped; heights come from the table.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 50,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        // Room around the label when the button is only as wide as it.
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: context.colors.green,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: context.shadows.greenButton,
        ),
        child: _LabelWithIcon(
          label: label,
          icon: icon,
          style: AppText.buttonLarge.c(context.colors.onGreen),
          color: context.colors.onGreen,
        ),
      ),
    );
  }
}

/// White on the hero gradient (spec §4.3 row 2).
class PrimaryOnGradientButton extends StatelessWidget {
  const PrimaryOnGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.onHero,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: context.shadows.onGradientButton,
        ),
        child: Text(
          label,
          style: AppText.buttonLarge.c(context.colors.onGradientButtonText),
        ),
      ),
    );
  }
}

/// Transparent with a white hairline, for use on the gradient.
class OutlinedOnGradientButton extends StatelessWidget {
  const OutlinedOnGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: context.colors.heroOutline),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)
              .c(context.colors.onHero),
        ),
      ),
    );
  }
}

/// Neutral fill, dark green label.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 44,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final String? icon;

  /// Label and icon colour; greenDark by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.neutralTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: _LabelWithIcon(
          label: label,
          icon: icon,
          style: AppText.buttonSmall.c(color ?? context.colors.greenDark),
          color: color ?? context.colors.greenDark,
          iconSize: 17,
        ),
      ),
    );
  }
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.danger,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: AppText.buttonLarge.c(context.colors.onDanger)),
      ),
    );
  }
}

/// White circle with a hairline border — share, back, stepper controls.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 50,
    this.iconSize = 19,
    this.color,
    this.bordered = true,
    this.shadow,
  });

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final bool bordered;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.card,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: context.colors.border) : null,
          boxShadow: shadow,
        ),
        child: AppIcon(
          icon,
          size: iconSize,
          color: color ?? context.colors.greenDark,
        ),
      ),
    );
  }
}

class _LabelWithIcon extends StatelessWidget {
  const _LabelWithIcon({
    required this.label,
    required this.style,
    required this.color,
    this.icon,
    this.iconSize = 18,
  });

  final String label;
  final TextStyle style;
  final Color color;
  final String? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final name = icon;
    if (name == null) return Text(label, style: style);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(name, size: iconSize, color: color),
        const SizedBox(width: 8),
        Text(label, style: style),
      ],
    );
  }
}

/// Keeps every button at the 44px minimum target and gives the iOS pressed
/// state: dims on touch, eases back on release.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(onTap: onTap, child: child);
}
