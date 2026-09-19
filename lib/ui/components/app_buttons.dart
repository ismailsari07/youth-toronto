import 'package:flutter/material.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

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
        decoration: BoxDecoration(
          color: AppColor.green,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadow.greenButton,
        ),
        child: _LabelWithIcon(
          label: label,
          icon: icon,
          style: AppText.buttonLarge.c(Colors.white),
          color: Colors.white,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              offset: Offset(0, 4),
              blurRadius: 14,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(label, style: AppText.buttonLarge.c(AppColor.greenDark)),
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
          border: Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)
              .c(Colors.white),
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
        decoration: BoxDecoration(
          color: AppColor.neutralTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: _LabelWithIcon(
          label: label,
          icon: icon,
          style: AppText.buttonSmall.c(AppColor.greenDark),
          color: AppColor.greenDark,
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
          color: AppColor.danger,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: AppText.buttonLarge.c(Colors.white)),
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
    this.color = AppColor.greenDark,
    this.bordered = true,
    this.shadow,
  });

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color color;
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
          color: AppColor.card,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: AppColor.border) : null,
          boxShadow: shadow,
        ),
        child: AppIcon(icon, size: iconSize, color: color),
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

/// Keeps every button at the 44px minimum target and gives a pressed state.
class _Tappable extends StatefulWidget {
  const _Tappable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _down ? 0.75 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
