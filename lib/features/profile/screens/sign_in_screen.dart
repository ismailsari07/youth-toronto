import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
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
  String? _error;

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
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PlainNavBar(
            eyebrow: 'ACCOUNT',
            title: 'Welcome back',
            subtitle: 'Sign in to register for events',
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
                      label: 'Email',
                      icon: AppIcons.mail,
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    AppField(
                      label: 'Password',
                      icon: AppIcons.lock,
                      controller: _password,
                      obscure: true,
                      divided: true,
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
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? 'Signing in…' : 'Sign in',
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
                        'New to Pape Mosque?',
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
                        'Create an account',
                        style: AppText.buttonLarge.c(AppColor.greenDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'An account is optional. Prayer times, events and '
                  'announcements work without one.',
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
