import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';

/// Shown instead of the whole app while this build is older than the
/// panel's `min_supported_version`. Only reached with an App Store link
/// (see [updateRequiredProvider]); there is no way past it but updating.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does not navigate */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final appStore = ref.watch(contentProvider.select((c) => c.links.appStore));
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.pageGutter),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColor.greenTint,
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      AppIcons.upload,
                      size: 32,
                      color: AppColor.green,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ).c(AppColor.ink),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 258),
                    child: Text(
                      l.updateRequiredBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                      ).c(AppColor.ink2),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (appStore != null)
                    PrimaryButton(
                      label: l.openAppStore,
                      onTap: () => _open(appStore),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
