import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../../../ui/components/refreshable.dart';
import '../data/marriage_application.dart';
import '../marriage_provider.dart';
import '../marriage_routes.dart';
import '../widgets/marriage_widgets.dart';
import '../widgets/withdraw_sheet.dart';

/// Spec §8a screen 6: the member's application. v1 shows only "Under
/// review" — later states are the Imam's concern and are not shown in the
/// app. The document is labelled generically; its file name is never kept.
class MarriageStatusScreen extends ConsumerStatefulWidget {
  const MarriageStatusScreen({super.key});

  @override
  ConsumerState<MarriageStatusScreen> createState() =>
      _MarriageStatusScreenState();
}

class _MarriageStatusScreenState extends ConsumerState<MarriageStatusScreen> {
  bool _leaving = false;

  AppLocalizations get l => context.l10n;

  Future<void> _withdraw() async {
    final withdrawn = await showWithdrawSheet(context);
    if (!withdrawn || !mounted) return;
    _leaving = true;
    ref.invalidate(myApplicationProvider);
    final messenger = ScaffoldMessenger.of(context);
    context.pushReplacement(MarriageRoutes.upload);
    messenger.showSnackBar(
      SnackBar(content: Text(l.withdrawn)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final application = ref.watch(myApplicationProvider);

    // Withdrawn elsewhere (another device): nothing to show, go to Upload.
    ref.listen(myApplicationProvider, (_, next) {
      if (!_leaving && next is AsyncData<MarriageApplication?> &&
          next.value == null) {
        _leaving = true;
        context.pushReplacement(MarriageRoutes.upload);
      }
    });

    return switch (application) {
      AsyncData(value: final app?) => _body(app),
      AsyncError() => _frame(
          state: 'error',
          subtitle: null,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpace.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.applicationUnavailable,
                    style: AppText.body.c(AppColor.ink2),
                  ),
                  const SizedBox(height: 14),
                  GhostButton(
                    label: l.tryAgain,
                    onTap: () => ref.invalidate(myApplicationProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      _ => _frame(state: 'loading', subtitle: null, children: const []),
    };
  }

  /// [state] keys the content, so it fades in when the application arrives
  /// instead of snapping into the empty frame.
  Widget _frame({
    required String state,
    required String? subtitle,
    required List<Widget> children,
  }) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.marriageEyebrow,
            title: l.yourApplication,
            subtitle: subtitle,
          ),
          Expanded(
            // The same iOS pull-to-refresh as the tab roots.
            child: RefreshableList(
              onRefresh: () async {
                ref.invalidate(myApplicationProvider);
                await ref
                    .read(myApplicationProvider.future)
                    .then<void>((_) {}, onError: (_) {});
              },
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
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

  Widget _body(MarriageApplication app) {
    return _frame(
      state: 'application',
      subtitle: l.submittedOn(dayMonth(l, app.createdAt)),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(),
              const SizedBox(height: 12),
              Text(
                l.underReviewBody,
                style: AppText.body.c(AppColor.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        SectionHeader(title: l.yourDocument),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            children: [
              FileTile(
                typeLabel: app.kind.label,
                caption: '${fileSize(l, app.sizeBytes)} · ${app.kind.label}',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: l.view,
                      icon: AppIcons.eye,
                      height: 46,
                      onTap: () => context.push(MarriageRoutes.view, extra: app),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: l.replace,
                      icon: AppIcons.replace,
                      height: 46,
                      onTap: () =>
                          context.push(MarriageRoutes.upload, extra: true),
                    ),
                  ),
                ],
              ),
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
            onTap: _withdraw,
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
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ).c(AppColor.danger),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.withdrawCaption,
                        style: const TextStyle(fontSize: 12.5)
                            .c(AppColor.ink3),
                      ),
                    ],
                  ),
                ),
                const RowChevron(color: Color(0xFFC99A95)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
