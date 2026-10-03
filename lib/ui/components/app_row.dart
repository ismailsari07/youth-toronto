import 'package:flutter/material.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'motion.dart';

/// The palette of a row's leading icon circle (spec §4.2).
enum RowTone { green, neutral, blue, gold, danger }

extension on RowTone {
  Color get fill => switch (this) {
        RowTone.green => AppColor.greenTint,
        RowTone.neutral => AppColor.neutralTint,
        RowTone.blue => AppColor.blueTint,
        RowTone.gold => AppColor.goldCircle,
        RowTone.danger => AppColor.dangerTint,
      };

  Color get glyph => switch (this) {
        RowTone.green => AppColor.green,
        RowTone.neutral => AppColor.ink3,
        RowTone.blue => AppColor.blue,
        RowTone.gold => AppColor.goldTextSoft,
        RowTone.danger => AppColor.danger,
      };
}

/// 38×38 icon circle used by list rows. [square] gives the announcement
/// variant (spec §7.4: a rounded square, so announcements read as a
/// different species from events).
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.tone = RowTone.green,
    this.size = 38,
    this.iconSize = 19,
    this.square = false,
    this.fill,
    this.glyphColor,
  });

  final String icon;
  final RowTone tone;
  final double size;
  final double iconSize;
  final bool square;
  final Color? fill;
  final Color? glyphColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill ?? tone.fill,
        borderRadius: BorderRadius.circular(square ? 12 : AppRadius.pill),
      ),
      child: AppIcon(icon, size: iconSize, color: glyphColor ?? tone.glyph),
    );
  }
}

/// Spec §4.2. 64 tall: 13 vertical padding around 38 of content, 18 horizontal,
/// 13 gap. Rows after the first carry a hairline top border.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    this.icon,
    this.tone = RowTone.green,
    this.squareIcon = false,
    this.iconFill,
    this.iconGlyph,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.trailing,
    this.onTap,
    this.divided = false,
    this.background,
    this.leading,
  });

  final String? icon;
  final RowTone tone;
  final bool squareIcon;
  final Color? iconFill;
  final Color? iconGlyph;
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divided;
  final Color? background;

  /// Replaces the icon bubble entirely (e.g. a date badge).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final lead = leading ??
        (icon == null
            ? null
            : IconBubble(
                icon: icon!,
                tone: tone,
                square: squareIcon,
                fill: iconFill,
                glyphColor: iconGlyph,
              ));

    final row = Container(
      color: background,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.rowPaddingV,
        horizontal: AppSpace.rowPaddingH,
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead, const SizedBox(width: AppSpace.rowGap)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle ?? AppText.rowTitle.c(AppColor.ink)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: subtitleStyle ?? AppText.caption.c(AppColor.ink3)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.rowGap),
            trailing!,
          ],
        ],
      ),
    );

    // The iOS table-cell wash while pressed, under the hairline.
    final pressable = Pressable(
      onTap: onTap,
      effect: PressEffect.highlight,
      child: row,
    );

    return divided
        ? DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColor.hairline)),
            ),
            child: pressable,
          )
        : pressable;
  }
}

/// The disclosure chevron used as a row's trailing element.
class RowChevron extends StatelessWidget {
  const RowChevron({super.key, this.color = AppColor.chevron, this.size = 17});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      AppIcon(AppIcons.chevronRight, size: size, color: color);
}

/// Stacks rows into one grouped card, adding the hairline between them.
class GroupedRows extends StatelessWidget {
  const GroupedRows({super.key, required this.rows, this.radius = AppRadius.card});

  final List<Widget> rows;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadow.card,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
