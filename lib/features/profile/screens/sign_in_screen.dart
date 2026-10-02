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
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.12. The auth logic is unchanged: AuthService.signInWithEmail.
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
    final error = await AuthService.signInWithEmail(
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) context.pop();
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
          PlainNavBar(
            eyebrow: l.accountEyebrow,
            title: l.welcomeBack,
            subtitle: l.signInSubtitle,
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
                FieldGroup(
                  children: [
                    AppField(
                      label: l.email,
                      icon: AppIcons.mail,
                      controller: _email,
                      hint: l.emailHint,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    AppField(
                      label: l.password,
                      icon: AppIcons.lock,
                      controller: _password,
                      obscure: true,
                      divided: true,
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
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? l.signingIn : l.signIn,
                  onTap: _busy ? null : _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColor.hairline, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l.noAccountYet,
                        style: const TextStyle(fontSize: 12).c(AppColor.ink3),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColor.hairline, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.pushReplacement('/profile/sign-up'),
                  behavior: HitTestBehavior.opaque,
                  child: AppCard(
                    radius: AppRadius.pill,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: Text(
                        l.createAccount,
                        style: AppText.buttonLarge.c(AppColor.greenDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.accountOptional,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)
                      .c(AppColor.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
