import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notification_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/reminders_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_sheet.dart';
import '../../../ui/components/motion.dart';

/// The Prayer home's bell: the same reminders switch as Profile and
/// Settings (one shared setting), and — if iOS has notifications turned off
/// for the app — a way to its Settings page.
Future<void> showRemindersSheet(BuildContext context) =>
    showAppSheet<void>(context: context, builder: (_) => const _RemindersSheet());

class _RemindersSheet extends ConsumerStatefulWidget {
  const _RemindersSheet();

  @override
  ConsumerState<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends ConsumerState<_RemindersSheet> {
  /// iOS's answer: false only once notifications are refused or switched
  /// off; null where it can't be told.
  bool? _allowed;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    // Back from the Settings app: show the new state straight away.
    _lifecycle = AppLifecycleListener(onResume: _checkPermission);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final allowed = await NotificationService.notificationsAllowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _set(bool on) async {
    // The sync asks for permission first when turning on, so check after.
    await ref.read(remindersEnabledProvider.notifier).set(on);
    await _checkPermission();
  }

  Future<void> _openSettings() async {
    try {
      // UIApplication.openSettingsURLString: the app's own Settings page.
      await launchUrl(Uri.parse('app-settings:'));
    } catch (_) {
      /* nothing to do: the button simply doesn't navigate */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final enabled = ref.watch(remindersEnabledProvider);
    final on = enabled.valueOrNull ?? true;
    final blocked = on && _allowed == false;

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
              l.prayerReminders,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(AppColor.ink),
            ),
            const SizedBox(height: 18),
            GroupedRows(
              rows: [
                AppListRow(
                  icon: on ? AppIcons.bell : AppIcons.bellOff,
                  title: l.prayerRemindersDetail,
                  trailing: AppSwitch(
                    value: on,
                    onChanged: enabled.hasValue ? _set : null,
                  ),
                ),
              ],
            ),
            FadeSwitch(
              animateSize: true,
              child: blocked
                  ? Padding(
                      key: const ValueKey('blocked'),
                      padding: const EdgeInsets.only(top: 14),
                      child: _BlockedNote(onOpenSettings: _openSettings),
                    )
                  : const SizedBox(key: ValueKey('ok'), width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedNote extends StatelessWidget {
  const _BlockedNote({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.remindersDeniedNote,
          style: const TextStyle(fontSize: 13.5, height: 1.45).c(AppColor.ink2),
        ),
        const SizedBox(height: 12),
        GhostButton(label: l.openSettings, onTap: onOpenSettings),
      ],
    );
  }
}
