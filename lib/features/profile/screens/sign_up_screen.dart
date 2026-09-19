import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';

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
  String? _error;

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
      _dob.text = longDate(picked);
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Please enter your name.');
    if (!email.contains('@')) {
      return setState(() => _error = 'Please enter a valid email.');
    }
    if (_password.text.length < 6) {
      return setState(
        () => _error = 'Password must be at least 6 characters.',
      );
    }
    if (_birthDate == null) {
      return setState(() => _error = 'Please choose your date of birth.');
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
            title: 'Create an account',
            subtitle: "So the office knows who's coming",
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
                      label: 'Full name',
                      icon: AppIcons.person,
                      controller: _name,
                      hint: 'Your name',
                    ),
                    AppField(
                      label: 'Email',
                      icon: AppIcons.mail,
                      controller: _email,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      divided: true,
                    ),
                    AppField(
                      label: 'Phone (optional)',
                      icon: AppIcons.phone,
                      controller: _phone,
                      hint: '647 000 0000',
                      keyboardType: TextInputType.phone,
                      divided: true,
                    ),
                    AppField(
                      label: 'Date of birth',
                      icon: AppIcons.calendar,
                      controller: _dob,
                      hint: 'Choose a date',
                      readOnly: true,
                      onTap: _pickDate,
                      divided: true,
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
                const SizedBox(height: 14),
                Text(
                  'Your details are shared only with the mosque office.',
                  style: const TextStyle(fontSize: 12.5, height: 1.5)
                      .c(AppColor.ink3),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? 'Creating…' : 'Create account',
                  onTap: _busy ? null : _submit,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pushReplacement('/profile/sign-in'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Already have an account? Sign in',
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
