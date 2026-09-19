import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/notification_service.dart';
import '../../../core/reminder_sync.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.10. Only the reminder toggle that actually works is shown: the
/// spec's Jumu'ah and "events and announcements" switches have no
/// implementation behind them, and a dead switch is worse than no switch.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _remindersOn;

  @override
  void initState() {
    super.initState();
    ReminderSync.isEnabled().then((on) {
      if (mounted) setState(() => _remindersOn = on);
    });
  }

  Future<void> _setReminders(bool value) async {
    setState(() => _remindersOn = value);
    await ReminderSync.setEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    } else {
      await NotificationService.cancelAll();
    }
    ReminderSync.sync();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: 'ACCOUNT',
            title: 'Settings',
            subtitle: user == null
                ? 'Not signed in'
                : 'Signed in as ${user.email ?? ''}',
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
                const SectionHeader(title: 'Notifications'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.bell,
                      title: 'Prayer reminders',
                      subtitle: '5 minutes before each iqamah',
                      trailing: AppSwitch(
                        value: _remindersOn ?? true,
                        onChanged: _remindersOn == null ? null : _setReminders,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                const SectionHeader(title: 'App'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.globe,
                      title: 'Language',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'EN',
                            style: const TextStyle(fontSize: 13.5)
                                .c(AppColor.ink3),
                          ),
                          const SizedBox(width: 6),
                          const RowChevron(),
                        ],
                      ),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.pin,
                      title: 'Mosque & contact',
                      trailing: const RowChevron(),
                      onTap: () => context.push('/profile/mosque'),
                    ),
                    const AppListRow(
                      divided: true,
                      icon: AppIcons.info,
                      title: 'About this app',
                      subtitle: 'Version 1.0',
                      trailing: RowChevron(),
                    ),
                  ],
                ),
                if (user != null) ...[
                  const SizedBox(height: AppSpace.cardGapWide),
                  const SectionHeader(title: 'Account'),
                  const SizedBox(height: AppSpace.sectionHeaderGap),
                  GroupedRows(
                    rows: [
                      AppListRow(
                        icon: AppIcons.signOut,
                        tone: RowTone.neutral,
                        title: 'Sign out',
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
                    child: GestureDetector(
                      onTap: () => context.push('/profile/delete'),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          const IconBubble(
                            icon: AppIcons.trash,
                            tone: RowTone.danger,
                          ),
                          const SizedBox(width: AppSpace.rowGap),
                          Expanded(
                            child: Text(
                              'Delete account',
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
