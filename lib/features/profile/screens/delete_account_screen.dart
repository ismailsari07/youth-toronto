import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.11, on the working deletion flow: AuthService.deleteAccount() calls
/// the `delete-account` edge function, which removes the auth user (and the
/// profile row with it) and then clears the local session.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready => _confirm.text.trim() == 'DELETE';

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AuthService.deleteAccount();
    if (!mounted) return;
    if (error == null) {
      context.go('/profile');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PlainNavBar(eyebrow: 'ACCOUNT', title: 'Delete account'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconBubble(
                            icon: AppIcons.trash,
                            tone: RowTone.danger,
                            size: 44,
                            iconSize: 21,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              'This cannot be undone',
                              style: AppText.cardTitle.c(AppColor.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Deleting your account removes your name, email, phone '
                        'number and date of birth from the mosque’s records.',
                        style: AppText.body.c(AppColor.ink2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The app keeps working without an account: prayer '
                        'times, events and announcements are all available '
                        'signed out.',
                        style: AppText.body.c(AppColor.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                const SectionHeader(title: 'What stays'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    const AppListRow(
                      icon: AppIcons.bell,
                      title: 'Prayer reminders',
                      subtitle: 'Kept on this device; they are not tied to '
                          'your account',
                    ),
                    const AppListRow(
                      divided: true,
                      icon: AppIcons.check,
                      title: 'Attendance already recorded',
                      subtitle: 'Kept as a count, without your name',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                const SectionHeader(title: 'Confirm'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                FieldGroup(
                  children: [
                    AppField(
                      label: 'Type DELETE to confirm',
                      controller: _confirm,
                      hint: 'DELETE',
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 13.5).c(AppColor.danger),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.pageGutter,
              8,
              AppSpace.pageGutter,
              20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Opacity(
                    opacity: _ready && !_busy ? 1 : 0.4,
                    child: DestructiveButton(
                      label: _busy ? 'Deleting…' : 'Delete my account',
                      onTap: _ready && !_busy ? _delete : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: 'Keep my account',
                    height: 46,
                    onTap: _busy ? null : () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
