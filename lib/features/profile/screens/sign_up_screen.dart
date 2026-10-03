import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/motion.dart';

/// Spec §7.13. Collects what the office needs; the call itself is the existing
/// AuthService.signUpWithEmail.
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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
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
    });
    final error = await AuthService.signUpWithEmail(
      email,
      _password.text,
      name,
      phone: _phone.text.trim(),
      dateOfBirth: _birthDate!,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error == null ? null : (l) => authErrorText(l, error);
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
            title: l.createAccount,
            subtitle: l.signUpSubtitle,
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
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error(l),
                    style: const TextStyle(fontSize: 13.5).c(AppColor.danger),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  l.detailsSharedOnlyWithOffice,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)
                      .c(AppColor.ink3),
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
                        ).c(AppColor.green),
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
