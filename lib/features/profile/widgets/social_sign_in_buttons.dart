import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/social_auth.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/motion.dart';

/// "Continue with Apple" over "Continue with Google", then an "or" line
/// before the email form, on the sign-in and sign-up screens (since 1.1.0).
/// Apple comes first and at least as prominent (App Review 4.8): both are
/// full width, the same height and shape. iOS only; nothing elsewhere.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    required this.onApple,
    required this.onGoogle,
  });

  /// Null while a sign-in is running.
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;

  static const height = 50.0;

  @override
  Widget build(BuildContext context) {
    if (!socialSignInSupported) return const SizedBox.shrink();
    final l = context.l10n;
    final dark = context.colors.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Apple's own button: black on light, white on dark (HIG).
        Opacity(
          opacity: onApple == null ? 0.5 : 1,
          child: SignInWithAppleButton(
            key: const Key('apple-sign-in'),
            text: l.continueWithApple,
            height: height,
            style: dark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.black,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onPressed: onApple,
          ),
        ),
        const SizedBox(height: 12),
        _GoogleButton(label: l.continueWithGoogle, onTap: onGoogle),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Divider(color: context.colors.hairline, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l.orDivider,
                style: const TextStyle(fontSize: 12).c(context.colors.ink3),
              ),
            ),
            Expanded(
              child: Divider(color: context.colors.hairline, thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Google's branded button (light: white with a grey outline; dark: near
/// black), with the full-colour "G". Same size and shape as Apple's.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Pressable(
        key: const Key('google-sign-in'),
        onTap: onTap,
        child: Container(
          height: SocialSignInButtons.height,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF131314) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: dark ? const Color(0xFF8E918F) : const Color(0xFF747775),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(_googleG, width: 20, height: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? const Color(0xFFE3E3E3)
                        : const Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google's standard "G" mark, as on its sign-in buttons.
const _googleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';
