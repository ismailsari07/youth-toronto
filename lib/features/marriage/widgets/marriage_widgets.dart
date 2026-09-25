import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_controls.dart';

/// Spec §8a: greenTint strip, radius 18, padding 12/16, `shield-check` 18
/// green and one line of greenDark 12.5 copy.
class PrivacyStrip extends StatelessWidget {
  const PrivacyStrip({super.key, this.text = AppStrings.privacyStrip});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.greenTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.shieldCheck, size: 18, color: AppColor.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.4)
                  .c(AppColor.greenDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spec §8a: the "Under review" pill on the Profile row — 24 tall,
/// greenTint fill, greenDark 11/700.
class UnderReviewPill extends StatelessWidget {
  const UnderReviewPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBadge(
      label: AppStrings.underReview,
      fill: AppColor.greenTint,
      textColor: AppColor.greenDark,
      height: 24,
      fontSize: 11,
      letterSpacing: 0,
      horizontalPadding: 10,
    );
  }
}

/// Spec §8a screen 2: the drop zone — white, radius 26, 1.5 px dashed
/// `#BFD3C8` border, card shadow, padding 26/20/20.
class DropZoneCard extends StatelessWidget {
  const DropZoneCard({super.key, required this.child});

  final Widget child;

  static const _dash = Color(0xFFBFD3C8);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card,
      ),
      child: CustomPaint(
        painter: const _DashedRRectPainter(
          color: _dash,
          radius: AppRadius.card,
          strokeWidth: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  static const _dashLength = 6.0;
  static const _gapLength = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth,
          size.height - strokeWidth),
      Radius.circular(radius - inset),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dashLength + _gapLength) {
        canvas.drawPath(metric.extractPath(d, d + _dashLength), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// Spec §8a screens 3–4 and 6: a file on a card. 46×54 radius-12 tile with
/// the `document` icon and the type, a generic title (the real file name is
/// never kept), and a caption such as "1.8 MB · PDF".
class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.typeLabel,
    required this.caption,
    this.captionColor = AppColor.ink3,
    this.captionWeight = FontWeight.w400,
    this.danger = false,
    this.trailing,
  });

  final String typeLabel;
  final String caption;
  final Color captionColor;
  final FontWeight captionWeight;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tint = danger ? AppColor.dangerTint : AppColor.greenTint;
    final ink = danger ? AppColor.danger : AppColor.green;
    return Row(
      children: [
        Container(
          width: 46,
          height: 54,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.document, size: 20, color: ink),
              if (typeLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ).c(ink),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.yourDocument,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ).c(AppColor.ink),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                style: TextStyle(fontSize: 12.5, fontWeight: captionWeight)
                    .c(captionColor),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Spec §8a screen 3: 6 px track `#E3E8E5`, green fill, fully rounded.
class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColor.segmentTrack),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              heightFactor: 1,
              child: const ColoredBox(color: AppColor.green),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spec §8a screen 2: the Submit button while nothing is chosen —
/// fill `#E3E8E5`, text `#7C8A84`. Submission happens on pick, so it is
/// never enabled.
class DisabledSubmitButton extends StatelessWidget {
  const DisabledSubmitButton({super.key, this.label = AppStrings.submit});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.segmentTrack,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.buttonLarge.c(const Color(0xFF7C8A84)),
      ),
    );
  }
}

/// The caption under a sticky action: 12.5 ink3, centred.
class StickyCaption extends StatelessWidget {
  const StickyCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5).c(AppColor.ink3),
      ),
    );
  }
}
