import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/email_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../widgets/email_code.dart';

enum ResetStep { email, code, password }

/// "Şifremi unuttum": email → 6-digit code → new password, all in the app.
/// The code step reads the same whether or not the address has an account.
/// A right code signs in (Supabase's recovery), then the new password is
/// saved. Pops `true` when done, so the sign-in screen closes too.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.email = '',
    @visibleForTesting this.initialStep = ResetStep.email,
  });

  /// What was typed on the sign-in screen, if anything.
  final String email;

  final ResetStep initialStep;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  late ResetStep _step = widget.initialStep;
  bool _busy = false;
  AuthError? _error;
  String Function(AppLocalizations l)? _note;
  bool _noteIsError = true;

  String get _address => _email.text.trim();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _problem(String Function(AppLocalizations l) text) => setState(() {
        _error = null;
        _note = text;
        _noteIsError = true;
      });

  Future<void> _run(
    Future<AuthError?> Function() call,
    void Function() onSuccess,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    final error = await call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) onSuccess();
  }

  void _sendCode() {
    if (!_address.contains('@')) return _problem((l) => l.enterValidEmail);
    _run(
      () => EmailAuth.instance.requestPasswordReset(_address),
      () => setState(() => _step = ResetStep.code),
    );
  }

  void _verify() {
    final code = _code.text.trim();
    if (!isCompleteCode(code)) return _problem((l) => l.enterEmailCode);
    _run(
      () => EmailAuth.instance.verifyRecovery(_address, code),
      () => setState(() => _step = ResetStep.password),
    );
  }

  void _save() {
    if (_password.text.length < 6) return _problem((l) => l.passwordTooShort);
    _run(
      () => EmailAuth.instance.setNewPassword(_password.text),
      () {
        ProviderScope.containerOf(context).invalidate(userProfileProvider);
        final l = context.l10n;
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.passwordChanged)));
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _error;
    final note = _note;
    final (subtitle, form, button, busyLabel, action) = switch (_step) {
      ResetStep.email => (
          l.resetEmailSubtitle,
          FieldGroup(
            children: [
              AppField(
                label: l.email,
                icon: AppIcons.mail,
                controller: _email,
                hint: l.emailHint,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                last: true,
                onSubmit: _sendCode,
              ),
            ],
          ),
          l.sendCode,
          l.sendingCode,
          _sendCode,
        ),
      ResetStep.code => (
          l.resetCodeSubtitle(_address),
          EmailCodeField(controller: _code, onComplete: _verify),
          l.continueButton,
          l.checkingCode,
          _verify,
        ),
      ResetStep.password => (
          l.newPasswordSubtitle,
          FieldGroup(
            children: [
              AppField(
                label: l.newPassword,
                icon: AppIcons.lock,
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                last: true,
                onSubmit: _save,
              ),
            ],
          ),
          l.savePassword,
          l.saving,
          _save,
        ),
    };
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.accountEyebrow,
            title: l.resetPasswordTitle,
            subtitle: subtitle,
          ),
          Expanded(
            child: ListView(
              key: ValueKey(_step),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                form,
                if (error != null) AuthMessage(authErrorText(l, error)),
                if (note != null) AuthMessage(note(l), error: _noteIsError),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? busyLabel : button,
                  onTap: _busy ? null : action,
                ),
                if (_step == ResetStep.code) ...[
                  const SizedBox(height: 8),
                  ResendCodeButton(
                    send: () => EmailAuth.instance.requestPasswordReset(_address),
                    onResult: (e) => setState(() {
                      _error = e;
                      _note = e == null ? (l) => l.codeSentAgain : null;
                      _noteIsError = false;
                    }),
                  ),
                  const SizedBox(height: 18),
                  AuthNote(l.resetCodeNote),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
