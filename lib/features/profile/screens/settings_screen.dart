import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/feature_flags.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/push_provider.dart';
import '../../prayer/widgets/reminders_sheet.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../../push/push_widgets.dart';
import '../widgets/about_sheet.dart';
import '../widgets/appearance_sheet.dart';
import '../widgets/language_sheet.dart';

/// Spec §7.10. Notifications: the two push switches (since 1.0.8, where
/// push runs) and the prayer reminders while their flag is on. A dead
/// switch is worse than no switch, so the spec's Jumu'ah one stays out.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final push = ref.watch(pushProvider);
    final version = ref.watch(appVersionProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: context.colors.ground,
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
                if (push.supported || kPrayerRemindersEnabled) ...[
                  SectionHeader(title: l.notifications),
                  const SizedBox(height: AppSpace.sectionHeaderGap),
                  // iOS has them off: say so above the switches, which
                  // still save the choice for when they're back on.
                  if (push.denied) ...[
                    const PushDeniedCard(),
                    const SizedBox(height: AppSpace.cardGap),
                  ],
                  GroupedRows(
                    rows: [
                      if (push.supported) ...[
                        AppListRow(
                          icon: AppIcons.calendar,
                          title: l.pushEvents,
                          subtitle: l.pushEventsDetail,
                          trailing: AppSwitch(
                            value: push.events,
                            onChanged: (on) =>
                                ref.read(pushProvider.notifier).setEvents(on),
                          ),
                        ),
                        AppListRow(
                          divided: true,
                          icon: AppIcons.announcement,
                          title: l.pushAnnouncements,
                          subtitle: l.pushAnnouncementsDetail,
                          trailing: AppSwitch(
                            value: push.announcements,
                            onChanged: (on) => ref
                                .read(pushProvider.notifier)
                                .setAnnouncements(on),
                          ),
                        ),
                      ],
                      if (kPrayerRemindersEnabled)
                        RemindersRow(divided: push.supported),
                    ],
                  ),
                  const SizedBox(height: AppSpace.cardGapWide),
                ],
                SectionHeader(title: l.app),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    const LanguageRow(),
                    const AppearanceRow(divided: true),
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
                      subtitle: version == null ? null : l.versionLabel(version),
                      trailing: const RowChevron(),
                      onTap: () => showAboutSheet(context),
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
                              style: AppText.rowTitle.c(context.colors.danger),
                            ),
                          ),
                          RowChevron(color: context.colors.dangerChevron),
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
