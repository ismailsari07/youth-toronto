import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_sheet.dart';

/// "İsim ekle" on Profile (since 1.1.0): shown while the member's name is
/// still the automatic one (an Apple account that shared no name, or the
/// part of the email before the @). Saved once with set_my_initial_name().
Future<void> showAddNameSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const _AddNameSheet(),
  );
}

class _AddNameSheet extends ConsumerStatefulWidget {
  const _AddNameSheet();

  @override
  ConsumerState<_AddNameSheet> createState() => _AddNameSheetState();
}

class _AddNameSheetState extends ConsumerState<_AddNameSheet> {
  final _name = TextEditingController();
  bool _busy = false;
  String Function(AppLocalizations l)? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = (l) => l.enterName);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AuthService.setInitialName(name);
    if (!mounted) return;
    switch (result) {
      case InitialNameResult.saved || InitialNameResult.notNeeded:
        ref.invalidate(userProfileProvider);
        Navigator.of(context).pop();
      case InitialNameResult.invalid:
        setState(() {
          _busy = false;
          _error = (l) => l.enterName;
        });
      case InitialNameResult.failed:
        setState(() {
          _busy = false;
          _error = (l) => l.saveFailedLater;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _error;
    return Padding(
      // Above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.ground,
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
                    color: context.colors.grabber,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.addName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                    .c(context.colors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                l.addNameBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, height: 1.45)
                    .c(context.colors.ink3),
              ),
              const SizedBox(height: 18),
              FieldGroup(
                children: [
                  AppField(
                    label: l.fullName,
                    icon: AppIcons.person,
                    controller: _name,
                    hint: l.yourName,
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error(l),
                  style: const TextStyle(fontSize: 13.5).c(context.colors.danger),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: _busy ? l.saving : l.saveName,
                onTap: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
