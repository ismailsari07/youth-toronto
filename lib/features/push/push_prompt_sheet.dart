import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_prompt.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/push_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_buttons.dart';
import '../../ui/components/app_sheet.dart';

/// Our own sheet before the iOS prompt, so the one question iOS lets us
/// ask comes with a reason. Shown when [trigger] fires and the rules in
/// [PushPromptRules] allow it; only "Turn on notifications" leads to iOS.
Future<void> maybeShowPushPrompt(
  BuildContext context,
  WidgetRef ref,
  PromptTrigger trigger,
) async {
  final push = ref.read(pushProvider.notifier);
  if (!await push.claimPrompt(trigger) || !context.mounted) return;
  final allow = await showAppSheet<bool>(
    context: context,
    builder: (_) => const PushPromptSheet(),
  );
  if (allow == true) {
    await push.requestPermission();
  } else {
    // "Not now", or swiped away: both count.
    await PushPromptStore.recordDismissal(DateTime.now());
  }
}

/// After an event card's tap: the sheet rises over the event page once
/// its push transition has settled, so the member sees what they opened.
void promptAfterEventTap(BuildContext context, WidgetRef ref) {
  Future<void>.delayed(const Duration(milliseconds: 450), () {
    if (context.mounted) {
      maybeShowPushPrompt(context, ref, PromptTrigger.eventTap);
    }
  });
}

class PushPromptSheet extends StatelessWidget {
  const PushPromptSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.ground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.grabber,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.iconCircle,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.bell,
                  size: 32,
                  color: context.colors.selected,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.pushPromptTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(context.colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              l.pushPromptReason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.45)
                  .c(context.colors.ink3),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: l.pushPromptAllow,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: l.pushPromptLater,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
