import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/push_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_sheet.dart';
import '../../../ui/components/motion.dart';

/// Settings → About this app: the version, and the device code the mosque
/// uses to send this phone a test notification.
Future<void> showAboutSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const AboutSheet(),
  );
}

class AboutSheet extends ConsumerStatefulWidget {
  const AboutSheet({super.key});

  @override
  ConsumerState<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends ConsumerState<AboutSheet> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final version = ref.watch(appVersionProvider);
    final push = ref.watch(pushProvider);
    final code = push.deviceCode;

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
            const SizedBox(height: 20),
            Text(
              l.aboutThisApp,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(context.colors.ink),
            ),
            const SizedBox(height: 18),
            GroupedRows(
              rows: [
                AppListRow(
                  icon: AppIcons.info,
                  title: l.appVersion,
                  trailing: Text(
                    version ?? '—',
                    style: const TextStyle(fontSize: 13.5)
                        .c(context.colors.ink3),
                  ),
                ),
                if (push.supported)
                  _DeviceCodeRow(
                    code: code,
                    copied: _copied,
                    onCopy: code == null ? null : () => _copy(code),
                  ),
              ],
            ),
            if (push.supported) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l.deviceCodeNote,
                  style: AppText.caption.c(context.colors.ink3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceCodeRow extends StatelessWidget {
  const _DeviceCodeRow({
    required this.code,
    required this.copied,
    required this.onCopy,
  });

  final String? code;
  final bool copied;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.rowPaddingV,
          horizontal: AppSpace.rowPaddingH,
        ),
        child: Row(
          children: [
            const IconBubble(icon: AppIcons.bell),
            const SizedBox(width: AppSpace.rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.deviceCode, style: AppText.rowTitle.c(context.colors.ink)),
                  const SizedBox(height: 2),
                  SelectableText(
                    code ?? '—',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ).c(context.colors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.rowGap),
            Opacity(
              opacity: onCopy == null ? 0.4 : 1,
              child: Pressable(
                onTap: onCopy,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Text(
                    copied ? l.copied : l.copy,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ).c(context.colors.green),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
