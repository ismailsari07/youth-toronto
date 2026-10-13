import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_mode_provider.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_sheet.dart';

/// The Appearance row, on Profile and in Settings. Trailing text is the
/// member's choice: System, Light or Dark.
class AppearanceRow extends ConsumerWidget {
  const AppearanceRow({super.key, this.divided = false, this.iconGlyph});

  final bool divided;

  /// Overrides the icon's colour (Settings paints it `selected`).
  final Color? iconGlyph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(themeModeProvider);
    return AppListRow(
      divided: divided,
      icon: AppIcons.appearance,
      iconGlyph: iconGlyph,
      title: l.appearance,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label(l, mode),
            style: const TextStyle(fontSize: 13.5).c(context.colors.ink3),
          ),
          const SizedBox(width: 6),
          const RowChevron(),
        ],
      ),
      onTap: () => showAppearanceSheet(context),
    );
  }
}

String _label(AppLocalizations l, ThemeMode mode) => switch (mode) {
      ThemeMode.system => l.appearanceSystem,
      ThemeMode.light => l.appearanceLight,
      ThemeMode.dark => l.appearanceDark,
    };

/// System, then Light / Dark. Picking one saves it on this device and the
/// whole app repaints at once.
Future<void> showAppearanceSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(themeModeProvider);

    Future<void> choose(ThemeMode mode) async {
      await ref.read(themeModeProvider.notifier).set(mode);
      if (context.mounted) Navigator.of(context).pop();
    }

    Widget option(ThemeMode mode, {String? subtitle, bool divided = true}) {
      final on = selected == mode;
      return AppListRow(
        divided: divided,
        title: _label(l, mode),
        titleStyle: AppText.rowTitle
            .copyWith(fontWeight: on ? FontWeight.w700 : null)
            .c(on ? context.colors.selectedDeep : context.colors.ink),
        subtitle: subtitle,
        background: on ? context.colors.greenRowBg : null,
        trailing: on
            ? AppIcon(AppIcons.check, size: 20, color: context.colors.selected)
            : null,
        onTap: () => choose(mode),
      );
    }

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
              l.appearance,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(context.colors.ink),
            ),
            const SizedBox(height: 18),
            GroupedRows(
              rows: [
                option(
                  ThemeMode.system,
                  subtitle: l.appearanceSystemDetail,
                  divided: false,
                ),
                option(ThemeMode.light),
                option(ThemeMode.dark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
