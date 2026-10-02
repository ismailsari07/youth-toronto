import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.11, on the working deletion flow: AuthService.deleteAccount() calls
/// the `delete-account` edge function, which deletes any marriage-service
/// document and application, then the auth user (and the profile row with
/// it), and then clears the local session.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _busy = false;
  AuthError? _error;

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

  /// The confirmation word in the app's language (DELETE / SUPPRIMER /
  /// SİL). Case doesn't matter, and in Turkish "SIL" typed on a keyboard
  /// without İ counts too.
  bool get _ready {
    final l = context.l10n;
    String norm(String s) =>
        upper(s.trim(), l.localeName).replaceAll('İ', 'I');
    return norm(_confirm.text) == norm(l.deleteConfirmWord);
  }

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
        SnackBar(content: Text(context.l10n.accountDeleted)),
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
    final l = context.l10n;
    final error = _error;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.accountEyebrow, title: l.deleteAccount),
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
                              l.cannotBeUndone,
                              style: AppText.cardTitle.c(AppColor.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        // Shown to everyone, whether or not they applied, so
                        // the copy never reveals who used the service.
                        l.deleteAccountBody1,
                        style: AppText.body.c(AppColor.ink2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.deleteAccountBody2,
                        style: AppText.body.c(AppColor.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.whatStays),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.bell,
                      title: l.prayerReminders,
                      subtitle: l.remindersStay,
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.check,
                      title: l.attendanceRecorded,
                      subtitle: l.attendanceStays,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.confirm),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                FieldGroup(
                  children: [
                    AppField(
                      label: l.typeWordToConfirm(l.deleteConfirmWord),
                      controller: _confirm,
                      hint: l.deleteConfirmWord,
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authErrorText(l, error),
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
                      label: _busy ? l.deleting : l.deleteMyAccount,
                      onTap: _ready && !_busy ? _delete : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: l.keepMyAccount,
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
