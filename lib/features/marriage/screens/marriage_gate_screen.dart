import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../marriage_provider.dart';
import '../marriage_routes.dart';

/// Spec §8a screen 1: what the service is and how it stays private, for a
/// signed-out member. After signing in or creating an account the member
/// comes straight back here and is taken on to Upload (or Status).
class MarriageGateScreen extends ConsumerStatefulWidget {
  const MarriageGateScreen({super.key});

  @override
  ConsumerState<MarriageGateScreen> createState() => _MarriageGateScreenState();
}

class _MarriageGateScreenState extends ConsumerState<MarriageGateScreen> {
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    // Opened while already signed in (e.g. from a link): skip the gate.
    WidgetsBinding.instance.addPostFrameCallback((_) => _continueIfSignedIn());
  }

  Future<void> _authThenContinue(String route) async {
    await context.push(route);
    await _continueIfSignedIn();
  }

  Future<void> _continueIfSignedIn() async {
    if (!mounted || _continuing) return;
    if (ref.read(currentUserProvider) == null) return;
    setState(() => _continuing = true);
    final application = await ref
        .read(myApplicationProvider.future)
        .then<Object?>((a) => a, onError: (_) => null);
    if (!mounted) return;
    context.pushReplacement(
      application == null ? MarriageRoutes.upload : MarriageRoutes.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.marriageEyebrow,
            title: l.marriageGateTitle,
            subtitle: l.marriageGateSubtitle,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                24,
              ),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.cardPadding),
                  child: Text(
                    l.marriageGateBody,
                    style: AppText.body.c(AppColor.ink2),
                  ),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.yourPrivacy),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.shieldCheck,
                      title: l.privacyOnlyImam,
                      subtitle: l.privacyOnlyImamBody,
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.close,
                      title: l.privacyNoProfiles,
                      subtitle: l.privacyNoProfilesBody,
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.trash,
                      title: l.privacyWithdraw,
                      subtitle: l.privacyWithdrawBody,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l.marriageAgeNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5).c(AppColor.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: l.signInToContinue,
              onTap: _continuing
                  ? null
                  : () => _authThenContinue('/profile/sign-in'),
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: l.createAccount,
              height: 46,
              onTap: _continuing
                  ? null
                  : () => _authThenContinue('/profile/sign-up'),
            ),
            const SizedBox(height: 10),
            Text(
              l.marriageGateCaption,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5).c(AppColor.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
