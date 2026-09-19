import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth_service.dart';
import '../../../core/notification_service.dart';
import '../../../core/reminder_sync.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.9 — the Profile tab root, signed in or out. Phase B wires the
/// identity row, the reminders switch and the settings entries; the pushed
/// screens (settings, sign in/up, delete, mosque) land in phases F and G.
class ProfileRootScreen extends ConsumerStatefulWidget {
  const ProfileRootScreen({super.key});

  @override
  ConsumerState<ProfileRootScreen> createState() => _ProfileRootScreenState();
}

class _ProfileRootScreenState extends ConsumerState<ProfileRootScreen> {
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
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      children: [
        GradientTabHeader(
          title: 'Profile',
          row: user == null
              ? const HeroRow(
                  icon: AppIcons.person,
                  title: "You're not signed in",
                  subtitle: 'Sign in to register for events and keep your '
                      'reminders across devices.',
                  circleSize: 46,
                )
              : HeroRow(
                  icon: AppIcons.person,
                  title: (profile?['full_name'] as String?) ??
                      user.email?.split('@').first ??
                      'Member',
                  subtitle: user.email ?? '',
                  trailing: const RowChevron(color: Colors.white),
                ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const SectionHeader(title: 'Settings'),
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
            AppListRow(
              divided: true,
              icon: AppIcons.globe,
              title: 'Language',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EN',
                      style: const TextStyle(fontSize: 13.5).c(AppColor.ink3)),
                  const SizedBox(width: 6),
                  const RowChevron(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        GroupedRows(
          rows: [
            const AppListRow(
              icon: AppIcons.pin,
              title: 'Mosque & contact',
              trailing: RowChevron(),
            ),
            const AppListRow(
              divided: true,
              icon: AppIcons.info,
              title: 'About this app',
              subtitle: 'Version 1.0',
              trailing: RowChevron(),
            ),
            if (user != null)
              AppListRow(
                divided: true,
                icon: AppIcons.signOut,
                tone: RowTone.neutral,
                title: 'Sign out',
                onTap: () => AuthService.signOut(),
              ),
          ],
        ),
        if (user == null) ...[
          const SizedBox(height: AppSpace.cardGapWide),
          PrimaryButton(label: 'Sign in', onTap: () {}),
          const SizedBox(height: 8),
          GhostButton(label: 'Create an account', height: 46, onTap: () {}),
        ],
        const SizedBox(height: 20),
        Text(
          'Prayer times, events and announcements work without an account.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.5).c(AppColor.ink3),
        ),
      ],
    );
  }
}
