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
