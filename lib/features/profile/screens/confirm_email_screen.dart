import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_service.dart';
import '../../../core/email_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../widgets/email_code.dart';

/// What `/profile/confirm-email` takes as `extra`.
typedef ConfirmEmailArgs = ({String email, bool sendOnOpen});

/// "Check your email" after an email sign-up (or a sign-in refused with
/// `email_not_confirmed`): the 6-digit code from the email confirms the
/// address and signs in. Pops `true` once signed in, so the screen that
/// opened it can close too.
class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({
    super.key,
    required this.email,
    this.sendOnOpen = false,
  });

  final String email;

  /// From sign-in: no code was sent just now, so send one.
  final bool sendOnOpen;

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _code = TextEditingController();
  final _resend = GlobalKey<ResendCodeButtonState>();
  bool _busy = false;
  AuthError? _error;
  /// "Enter the code" (red) or "a new code was sent" (green).
  String Function(AppLocalizations l)? _note;
  bool _noteIsError = false;

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendFirst());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendFirst() async {
    final error = await EmailAuth.instance.resendSignUp(widget.email);
    if (!mounted) return;
    setState(() => _error = error);
  }

  Future<void> _verify() async {
    if (_busy) return;
    final code = _code.text.trim();
    if (!isCompleteCode(code)) {
      return setState(() {
        _error = null;
        _note = (l) => l.enterEmailCode;
        _noteIsError = true;
      });
    }
    setState(() {
      _busy = true;
      _error = null;
      _note = null;
    });
    final error = await EmailAuth.instance.verifySignUp(widget.email, code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      ProviderScope.containerOf(context).invalidate(userProfileProvider);
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _error;
    final note = _note;
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.accountEyebrow,
            title: l.confirmEmailTitle,
            subtitle: l.confirmEmailSubtitle(widget.email),
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
                EmailCodeField(controller: _code, onComplete: _verify),
                if (error != null) AuthMessage(authErrorText(l, error)),
                if (note != null) AuthMessage(note(l), error: _noteIsError),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _busy ? l.confirmingEmail : l.confirmEmailButton,
                  onTap: _busy ? null : _verify,
                ),
                const SizedBox(height: 8),
                ResendCodeButton(
                  key: _resend,
                  send: () => EmailAuth.instance.resendSignUp(widget.email),
                  onResult: (e) => setState(() {
                    _error = e;
                    _note = e == null ? (l) => l.codeSentAgain : null;
                    _noteIsError = false;
                  }),
                ),
                const SizedBox(height: 18),
                AuthNote(l.confirmLaterNote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
