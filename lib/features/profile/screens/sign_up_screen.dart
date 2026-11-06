import '../../../shared/birth_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/email_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../widgets/social_sign_in_buttons.dart';

/// Spec §7.13. Collects what the office needs; the call itself is the existing
/// AuthService.signUpWithEmail. Since 1.1.0 Apple / Google sit above the
/// form; they create the account without phone or date of birth (Profile
/// shows "Not added"; the marriage service asks for the date of birth).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _password = TextEditingController();
  DateTime? _birthDate;
  bool _busy = false;
  /// Rendered at build time, so it follows a language change.
  String Function(AppLocalizations l)? _error;

  /// The address already has an account: offer sign-in and the reset.
  bool _registered = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _password.dispose();
    super.dispose();
  }

  @visibleForTesting
  void debugSetBirthDate(DateTime date) => setState(() => _birthDate = date);

  Future<void> _pickDate() async {
    final picked = await showBirthDatePicker(context, initial: _birthDate);
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _dob.text = longDate(context.l10n, picked);
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty) return setState(() => _error = (l) => l.enterName);
    if (!email.contains('@')) {
      return setState(() => _error = (l) => l.enterValidEmail);
    }
    if (_password.text.length < 6) {
      return setState(() => _error = (l) => l.passwordTooShort);
    }
    if (_birthDate == null) {
      return setState(() => _error = (l) => l.chooseDob);
    }

    setState(() {
      _busy = true;
      _error = null;
      _registered = false;
    });
    final outcome = await EmailAuth.instance.signUp(
      email: email,
      password: _password.text,
      fullName: name,
      phone: _phone.text.trim(),
      dateOfBirth: _birthDate!,
    );
    if (!mounted) return;
    final error = outcome.error;
    setState(() {
      _busy = false;
      _registered = outcome.result == SignUpResult.alreadyRegistered;
      _error = error == null ? null : (l) => authErrorText(l, error);
    });
    switch (outcome.result) {
      case SignUpResult.signedIn:
        context.pop();
      case SignUpResult.confirmEmail:
        final signedIn = await context.push<bool>(
          '/profile/confirm-email',
          extra: (email: email, sendOnOpen: false),
        );
        if (signedIn == true && mounted) context.pop();
      case SignUpResult.alreadyRegistered || null:
        break;
    }
  }

  /// Apple or Google. A closed sheet shows nothing.
  Future<void> _social(Future<AuthError?> Function() signIn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await signIn();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error == null || error.kind == AuthFailure.cancelled
          ? null
          : (l) => authErrorText(l, error);
    });
    if (error == null) {
      // An Apple name may have been saved after the profile was fetched.
      ProviderScope.containerOf(context).invalidate(userProfileProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _error;
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.accountEyebrow,
            title: l.createAccount,
            subtitle: l.signUpSubtitle,
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                SocialSignInButtons(
                  onApple: _busy
                      ? null
                      : () => _social(AuthService.signInWithApple),
                  onGoogle: _busy
                      ? null
                      : () => _social(AuthService.signInWithGoogle),
                ),
                FieldGroup(
                  children: [
                    AppField(
                      label: l.fullName,
                      icon: AppIcons.person,
                      controller: _name,
                      hint: l.yourName,
                    ),
                    AppField(
                      label: l.email,
                      icon: AppIcons.mail,
                      controller: _email,
                      hint: l.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      divided: true,
                    ),
                    AppField(
                      label: l.phoneOptional,
                      icon: AppIcons.phone,
                      controller: _phone,
                      hint: '647 000 0000',
                      keyboardType: TextInputType.phone,
                      divided: true,
                    ),
                    AppField(
                      label: l.dobField,
                      icon: AppIcons.calendar,
                      controller: _dob,
                      hint: l.dobHint,
                      readOnly: true,
                      onTap: _pickDate,
                      divided: true,
                    ),
                    AppField(
                      label: l.password,
                      icon: AppIcons.lock,
                      controller: _password,
                      obscure: true,
                      divided: true,
                      last: true,
                      onSubmit: _busy ? null : _submit,
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
                if (_registered) _AlreadyRegistered(email: _email.text.trim()),
                const SizedBox(height: 14),
                Text(
                  l.detailsSharedOnlyWithOffice,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)
                      .c(context.colors.ink3),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? l.creatingAccount : l.createAccountButton,
                  onTap: _busy ? null : _submit,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Pressable(
                    onTap: () => context.pushReplacement('/profile/sign-in'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        l.alreadyHaveAccount,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ).c(context.colors.green),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// With "Confirm email" on, Supabase sends nothing to an address that
/// already has an account: say so and offer the two ways in.
class _AlreadyRegistered extends StatelessWidget {
  const _AlreadyRegistered({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget link(String key, String label, VoidCallback onTap) => Pressable(
          key: ValueKey(key),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 4),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)
                  .c(context.colors.green),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.emailAlreadyRegistered,
            style: const TextStyle(fontSize: 13.5, height: 1.4)
                .c(context.colors.danger),
          ),
          Wrap(
            children: [
              link('registered-sign-in', l.signIn,
                  () => context.pushReplacement('/profile/sign-in')),
              link('registered-reset', l.forgotPassword,
                  () => context.pushReplacement('/profile/reset-password', extra: email)),
            ],
          ),
        ],
      ),
    );
  }
}
