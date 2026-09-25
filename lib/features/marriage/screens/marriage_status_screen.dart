import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../widgets/marriage_widgets.dart';

/// Spec §8a screen 6. Stub until its phase lands; routed now so the
/// Profile entry and the gate have somewhere to go.
class MarriageStatusScreen extends StatelessWidget {
  const MarriageStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: AppStrings.marriageEyebrow,
            title: AppStrings.yourApplication,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.pageGutter,
              18,
              AppSpace.pageGutter,
              0,
            ),
            child: PrivacyStrip(),
          ),
        ],
      ),
    );
  }
}
