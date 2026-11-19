import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../../../ui/components/refreshable.dart';
import '../data/marriage_v2_service.dart';
import '../marriage_provider.dart';
import '../marriage_routes.dart';
import '../widgets/marriage_widgets.dart';
import '../widgets/withdraw_sheet.dart';

/// The member's encrypted application (form v2). Like the document
/// application it shows only "Under review"; later states are the Imam's
/// concern. The answers can't be shown again (the app has no key that opens
/// them), so changing something = withdraw and apply again.
class MarriageSubmittedScreen extends ConsumerStatefulWidget {
  const MarriageSubmittedScreen({super.key, this.justSent = false});

  /// Opened right after sending: the heading says so.
  final bool justSent;

  @override
  ConsumerState<MarriageSubmittedScreen> createState() => _MarriageSubmittedScreenState();
}

class _MarriageSubmittedScreenState extends ConsumerState<MarriageSubmittedScreen> {
  bool _leaving = false;

  AppLocalizations get l => context.l10n;

  String get _start => MarriageRoutes.startFor(formV2: ref.read(contentProvider).features.marriageFormV2);

  Future<void> _withdraw(MarriageSubmission submission) async {
    final withdrawn = await showWithdrawSheet(
      context,
      body: l.mfWithdrawSheetBody,
      action: () => MarriageV2Service.withdraw(submission),
    );
    if (!withdrawn || !mounted) return;
    _leaving = true;
    ref.invalidate(mySubmissionProvider);
    final messenger = ScaffoldMessenger.of(context);
    context.pushReplacement(_start);
    messenger.showSnackBar(SnackBar(content: Text(l.withdrawn)));
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(mySubmissionProvider);

    // Withdrawn elsewhere (another device): go to the start screen.
    ref.listen(mySubmissionProvider, (_, next) {
      if (!_leaving && next is AsyncData<MarriageSubmission?> && next.value == null) {
        _leaving = true;
        context.pushReplacement(_start);
      }
    });

    return switch (submission) {
      AsyncData(value: final s?) => _body(s),
      AsyncError() => _frame(
          state: 'error',
          subtitle: null,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpace.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.applicationUnavailable, style: AppText.body.c(context.colors.ink2)),
                  const SizedBox(height: 14),
                  GhostButton(label: l.tryAgain, onTap: () => ref.invalidate(mySubmissionProvider)),
                ],
              ),
            ),
          ],
        ),
      _ => _frame(state: 'loading', subtitle: null, children: const []),
    };
  }

  Widget _frame({required String state, required String? subtitle, required List<Widget> children}) {
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.marriageEyebrow, title: l.yourApplication, subtitle: subtitle),
          Expanded(
            child: RefreshableList(
              onRefresh: () async {
                ref.invalidate(mySubmissionProvider);
                await ref.read(mySubmissionProvider.future).then<void>((_) {}, onError: (_) {});
              },
              padding: const EdgeInsets.fromLTRB(AppSpace.pageGutter, 18, AppSpace.pageGutter, 40),
              children: [
                FadeSwitch(
                  child: Column(
                    key: ValueKey(state),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(MarriageSubmission s) {
    return _frame(
      state: 'application',
      subtitle: l.mfSentOn(dayMonth(l, s.createdAt)),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.justSent) ...[
                Text(l.mfSentTitle, style: AppText.cardTitle.c(context.colors.ink)),
                const SizedBox(height: 10),
              ],
              const StatusPill(),
              const SizedBox(height: 12),
              Text(l.mfSentBody, style: AppText.body.c(context.colors.ink2)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.lock, size: 18, color: context.colors.ink3),
              const SizedBox(width: 10),
              Expanded(child: Text(l.mfNoViewNote, style: AppText.body.c(context.colors.ink2))),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const PrivacyStrip(),
        const SizedBox(height: AppSpace.cardGapWide),
        AppCard(
          radius: AppRadius.listCard,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          child: Pressable(
            onTap: () => _withdraw(s),
            child: Row(
              children: [
                const IconBubble(icon: AppIcons.trash, tone: RowTone.danger),
                const SizedBox(width: AppSpace.rowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.withdrawTitle,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600).c(context.colors.danger),
                      ),
                      const SizedBox(height: 2),
                      Text(l.mfWithdrawCaption, style: const TextStyle(fontSize: 12.5).c(context.colors.ink3)),
                    ],
                  ),
                ),
                RowChevron(color: context.colors.dangerChevron),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
