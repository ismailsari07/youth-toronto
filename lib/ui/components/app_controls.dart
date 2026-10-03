import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Spec §4.4. iOS geometry drawn to the design's numbers rather than
/// Material's, so it matches the canvas exactly: track 51×31, knob 27 inset 2,
/// 22 of travel. Wrapped in a 51×44 hit area.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _trackOff = Color(0xFFD6DCD9);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 51,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: AppMotion.standard,
            width: 51,
            height: 31,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? AppColor.green : _trackOff,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: AppMotion.standard,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.switchKnob,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spec §4.5. Full-width track 40 tall, radius 11, white thumb with a shadow.
class AppSegmented extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 4) / labels.length;
        return Container(
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColor.segmentTrack,
            borderRadius: BorderRadius.circular(AppRadius.segmentOuter),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: segmentWidth * index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.segmentThumb),
                    boxShadow: AppShadow.segmentThumb,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(i),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            labels[i],
                            style: i == index
                                ? AppText.segment.c(AppColor.ink)
                                : AppText.segment
                                    .copyWith(fontWeight: FontWeight.w500)
                                    .c(AppColor.ink2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Spec §4.6, list variant: 58×64, radius 16, weekday / day / month stacked.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: AppColor.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badgeWeekday(context.l10n, date),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ).c(AppColor.green),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              height: 1.15,
            ).c(AppColor.greenDark),
          ),
          Text(
            badgeMonth(context.l10n, date),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ).c(AppColor.ink2),
          ),
        ],
      ),
    );
  }
}

/// Spec §4.6, photo variant: white, radius 14, sits over the photo band.
class DateBadgeOnPhoto extends StatelessWidget {
  const DateBadgeOnPhoto({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.dateBadgeOnPhoto),
        boxShadow: AppShadow.badgeOnPhoto,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeWeekday(context.l10n, date),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ).c(AppColor.green),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              height: 1.2,
            ).c(AppColor.greenDark),
          ),
          Text(
            badgeMonth(context.l10n, date),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ).c(AppColor.ink2),
          ),
        ],
      ),
    );
  }
}

/// A recurring event's left element: a light 40×40 greenTint circle with the
/// event's category icon in green, plus a small repeat mark on its
/// bottom-right corner so the card still reads as recurring at a glance.
/// It sits centred in the date tile's 58×64 footprint, so one-off and
/// recurring cards keep their text columns aligned.
///
/// [onPhoto] is the variant over a photo band: a white circle (which holds
/// up against any photograph) with a soft shadow, and no footprint box.
/// [spokenLabel] ("Repeats weekly") is what screen readers announce.
class RecurringBadge extends StatelessWidget {
  const RecurringBadge({
    super.key,
    required this.icon,
    required this.spokenLabel,
    this.onPhoto = false,
  });

  final String icon;
  final String spokenLabel;
  final bool onPhoto;

  static const _size = 40.0;
  static const _markSize = 17.0;

  @override
  Widget build(BuildContext context) {
    final circle = SizedBox(
      width: _size + 4,
      height: _size + 4,
      child: Stack(
        children: [
          Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onPhoto ? Colors.white : AppColor.greenTint,
              shape: BoxShape.circle,
              boxShadow: onPhoto ? AppShadow.badgeOnPhoto : null,
            ),
            child: AppIcon(icon, size: 19, color: AppColor.green),
          ),
          // The repeat mark: white ring so it separates from the circle.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _markSize,
              height: _markSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const AppIcon(
                AppIcons.repeat,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: spokenLabel,
      excludeSemantics: true,
      child: onPhoto
          ? circle
          : SizedBox(width: 58, height: 64, child: Center(child: circle)),
    );
  }
}

/// Small pill label: `NEXT PRAYER`, `NOW`, `3 days`, `New`.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.fill = AppColor.green,
    this.textColor = Colors.white,
    this.height = 17,
    this.fontSize = 9,
    this.letterSpacing = 0.7,
    this.horizontalPadding = 7,
  });

  final String label;
  final Color fill;
  final Color textColor;
  final double height;
  final double fontSize;
  final double letterSpacing;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: letterSpacing,
        ).c(textColor),
      ),
    );
  }
}
