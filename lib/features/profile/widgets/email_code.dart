import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth_service.dart';
import '../../../core/email_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_text_input.dart';
import '../../../ui/components/motion.dart';

/// Seconds between two "send the code again" taps. Supabase refuses a new
/// email sooner than its own interval (set to 60 s), so this matches it.
const kResendCooldown = 60;

/// The 6-digit code from the email, large and centred. iOS offers the code
/// from Mail above the keyboard (one-time code autofill).
class EmailCodeField extends StatelessWidget {
  const EmailCodeField({
    super.key,
    required this.controller,
    required this.onComplete,
  });

  final TextEditingController controller;

  /// Called once all digits are typed or pasted.
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: context.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.emailCodeLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ).c(context.colors.ink3),
          ),
          AppTextInput(
            key: const ValueKey('email-code'),
            controller: controller,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            autofocus: true,
            textAlign: TextAlign.center,
            maxLength: kEmailCodeLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            last: true,
            onSubmit: onComplete,
            onChanged: (v) {
              if (isCompleteCode(v)) onComplete();
            },
            cursorColor: context.colors.green,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              fontFeatures: [FontFeature.tabularFigures()],
            ).c(context.colors.ink),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              contentPadding: const EdgeInsets.only(top: 6),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '0' * kEmailCodeLength,
              hintStyle: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
              ).c(context.colors.placeholder),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Kodu tekrar gönder", greyed out with the seconds left while waiting.
/// [send] returns null on success; the wait starts again after each send,
/// and also when the widget appears (a code was just sent).
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.send,
    required this.onResult,
    this.startWaiting = true,
  });

  final Future<AuthError?> Function() send;

  /// The outcome of a tap: null when a new code is on its way.
  final ValueChanged<AuthError?> onResult;

  final bool startWaiting;

  @override
  State<ResendCodeButton> createState() => ResendCodeButtonState();
}

class ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _left = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.startWaiting) restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts the wait, e.g. after the screen sent a code itself.
  void restart() {
    _timer?.cancel();
    setState(() => _left = kResendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _tap() async {
    setState(() => _sending = true);
    final error = await widget.send();
    if (!mounted) return;
    setState(() => _sending = false);
    // A rate limit means Supabase's own wait isn't over: wait again too.
    if (error == null || error.kind == AuthFailure.rateLimited) restart();
    widget.onResult(error);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final waiting = _left > 0;
    final enabled = !waiting && !_sending;
    return Center(
      child: Pressable(
        onTap: enabled ? _tap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            waiting ? l.resendCodeIn(_left) : l.resendCode,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
                .c(enabled ? context.colors.green : context.colors.ink3),
          ),
        ),
      ),
    );
  }
}

/// A short line under the form: an error in red, or a note in grey.
class AuthMessage extends StatelessWidget {
  const AuthMessage(this.text, {super.key, this.error = true});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13.5, height: 1.4)
              .c(error ? context.colors.danger : context.colors.greenDark),
        ),
      );
}

/// The grey explanatory text at the bottom of the auth screens.
class AuthNote extends StatelessWidget {
  const AuthNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, height: 1.5).c(context.colors.ink3),
      );
}
