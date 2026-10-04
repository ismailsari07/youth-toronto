import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/reminders_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../widgets/language_sheet.dart';

/// Spec §7.10. Only the reminder toggle that actually works is shown: the
/// spec's Jumu'ah and "events and announcements" switches have no
/// implementation behind them, and a dead switch is worse than no switch.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.accountEyebrow,
            title: l.settings,
            subtitle: user == null
                ? l.notSignedInShort
                : l.signedInAs(user.email ?? ''),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                SectionHeader(title: l.notifications),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.bell,
                      title: l.prayerReminders,
                      subtitle: l.prayerRemindersDetail,
                      trailing: AppSwitch(
                        value: ref.watch(remindersEnabledProvider).valueOrNull ?? true,
                        onChanged: ref.watch(remindersEnabledProvider).hasValue
                            ? (on) => ref.read(remindersEnabledProvider.notifier).set(on)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.app),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    const LanguageRow(),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.pin,
                      title: l.mosqueAndContact,
                      trailing: const RowChevron(),
                      onTap: () => context.push('/profile/mosque'),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.info,
                      title: l.aboutThisApp,
                      subtitle: l.versionLabel('1.0'),
                      trailing: const RowChevron(),
                    ),
                  ],
                ),
                if (user != null) ...[
                  const SizedBox(height: AppSpace.cardGapWide),
                  SectionHeader(title: l.account),
                  const SizedBox(height: AppSpace.sectionHeaderGap),
                  GroupedRows(
                    rows: [
                      AppListRow(
                        icon: AppIcons.signOut,
                        tone: RowTone.neutral,
                        title: l.signOut,
                        onTap: () async {
                          await AuthService.signOut();
                          if (context.mounted) context.pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.cardGap),
                  AppCard(
                    radius: AppRadius.listCard,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 18,
                    ),
                    child: Pressable(
                      onTap: () => context.push('/profile/delete'),
                      child: Row(
                        children: [
                          const IconBubble(
                            icon: AppIcons.trash,
                            tone: RowTone.danger,
                          ),
                          const SizedBox(width: AppSpace.rowGap),
                          Expanded(
                            child: Text(
                              l.deleteAccount,
                              style: AppText.rowTitle.c(AppColor.danger),
                            ),
                          ),
                          const RowChevron(color: Color(0xFFC99A95)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
