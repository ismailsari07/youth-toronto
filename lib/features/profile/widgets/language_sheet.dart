import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/locale_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_row.dart';

/// The Language row, on Profile and in Settings. Trailing text is the
/// member's choice in its own language, or "Auto" while following the
/// device.
class LanguageRow extends ConsumerWidget {
  const LanguageRow({super.key, this.divided = false});

  final bool divided;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(localeOverrideProvider);
    final l = context.l10n;
    final current = override == null
        ? l.languageAuto
        : appLanguages
            .firstWhere((lang) => lang.code == override.languageCode)
            .autonym;
    return AppListRow(
      divided: divided,
      icon: AppIcons.globe,
      title: l.language,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(current, style: const TextStyle(fontSize: 13.5).c(AppColor.ink3)),
          const SizedBox(width: 6),
          const RowChevron(),
        ],
      ),
      onTap: () => showLanguageSheet(context),
    );
  }
}

/// Device language, then English / Français / Türkçe. Picking one saves it
/// and the whole app switches at once.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6B0F1C17), // rgba(15,28,23,.42)
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(localeOverrideProvider);

    Future<void> choose(Locale? locale) async {
      await ref.read(localeOverrideProvider.notifier).set(locale);
      if (context.mounted) Navigator.of(context).pop();
    }

    Widget option({
      required String title,
      String? subtitle,
      required Locale? locale,
      bool divided = true,
    }) {
      final on = selected?.languageCode == locale?.languageCode;
      return AppListRow(
        divided: divided,
        title: title,
        titleStyle: AppText.rowTitle
            .copyWith(fontWeight: on ? FontWeight.w700 : null)
            .c(on ? AppColor.greenDeep : AppColor.ink),
        subtitle: subtitle,
        background: on ? AppColor.greenRowBg : null,
        trailing: on
            ? const AppIcon(AppIcons.check, size: 20, color: AppColor.green)
            : null,
        onTap: () => choose(locale),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.ground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: const Color(0xFFDDE3E0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.language,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(AppColor.ink),
            ),
            const SizedBox(height: 18),
            GroupedRows(
              rows: [
                option(
                  title: l.deviceLanguage,
                  subtitle: l.deviceLanguageDetail,
                  locale: null,
                  divided: false,
                ),
                for (final lang in appLanguages)
                  option(title: lang.autonym, locale: Locale(lang.code)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
