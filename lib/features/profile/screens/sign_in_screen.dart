import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/email_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';
import '../widgets/social_sign_in_buttons.dart';

/// Spec §7.12: AuthService.signInWithEmail, and since 1.1.0 Sign in with
/// Apple / Google above the form (SocialSignInButtons).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  AuthError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    final error = await EmailAuth.instance.signIn(email, _password.text);
    if (!mounted) return;
    final unconfirmed = error?.kind == AuthFailure.emailNotConfirmed;
    setState(() {
      _busy = false;
      _error = unconfirmed ? null : error;
    });
    if (error == null) return context.pop();
    // The account waits for its code: send a new one and ask for it.
    if (unconfirmed) {
      await _then(context.push<bool>(
        '/profile/confirm-email',
        extra: (email: email, sendOnOpen: true),
      ));
    }
  }

  /// Closes this screen too once the pushed one signed in.
  Future<void> _then(Future<bool?> pushed) async {
    final signedIn = await pushed;
    if (signedIn == true && mounted) context.pop();
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
      _error = error?.kind == AuthFailure.cancelled ? null : error;
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
            title: l.welcomeBack,
            subtitle: l.signInSubtitle,
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
                      label: l.email,
                      icon: AppIcons.mail,
                      controller: _email,
                      hint: l.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
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
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Pressable(
                    key: const ValueKey('forgot-password'),
                    onTap: _busy
                        ? null
                        : () => _then(context.push<bool>(
                              '/profile/reset-password',
                              extra: _email.text.trim(),
                            )),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
                      child: Text(
                        l.forgotPassword,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ).c(context.colors.green),
                      ),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authErrorText(l, error),
                    style: const TextStyle(fontSize: 13.5).c(context.colors.danger),
                  ),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? l.signingIn : l.signIn,
                  onTap: _busy ? null : _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: context.colors.hairline, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l.noAccountYet,
                        style: const TextStyle(fontSize: 12).c(context.colors.ink3),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: context.colors.hairline, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Pressable(
                  onTap: () => context.pushReplacement('/profile/sign-up'),
                  child: AppCard(
                    radius: AppRadius.pill,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        l.createAccount,
                        style: AppText.buttonLarge.c(context.colors.greenDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.accountOptional,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)
                      .c(context.colors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
