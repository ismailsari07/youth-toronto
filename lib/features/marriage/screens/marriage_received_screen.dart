import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../marriage_routes.dart';
import '../widgets/marriage_widgets.dart';

/// Spec §8a screen 5. No nav bar: the upload is done and the only way on is
/// "Done", which opens the member's application.
class MarriageReceivedScreen extends StatelessWidget {
  const MarriageReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.pageGutter,
          topInset(context) + 36,
          AppSpace.pageGutter,
          24,
        ),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: heroGradient,
                color: AppColor.heroBase,
                shape: BoxShape.circle,
                boxShadow: AppShadow.hero,
              ),
              child: const AppIcon(
                AppIcons.check,
                size: 40,
                color: AppColor.onHero,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            AppStrings.receivedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ).c(AppColor.ink),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.receivedBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, height: 1.45)
                .c(AppColor.ink2),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: AppStrings.whatHappensNext),
          const SizedBox(height: AppSpace.sectionHeaderGap),
          const GroupedRows(
            rows: [
              AppListRow(
                leading: _StepNumber(1),
                title: AppStrings.nextImamReads,
                subtitle: AppStrings.nextImamReadsBody,
              ),
              AppListRow(
                divided: true,
                leading: _StepNumber(2),
                title: AppStrings.nextContacted,
                subtitle: AppStrings.nextContactedBody,
              ),
              AppListRow(
                divided: true,
                leading: _StepNumber(3),
                title: AppStrings.nextYouDecide,
                subtitle: AppStrings.nextYouDecideBody,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.cardGapWide),
          const PrivacyStrip(),
        ],
      ),
      bottomNavigationBar: StickyBottomBar(
        child: PrimaryButton(
          label: AppStrings.done,
          onTap: () => context.pushReplacement(MarriageRoutes.status),
        ),
      ),
    );
  }
}

/// 28×28 greenTint circle with the step number, 13/700.
class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColor.greenTint,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)
            .c(AppColor.greenDark),
      ),
    );
  }
}
