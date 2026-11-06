import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Where links in the app's auth emails go: a page on the website that says
/// "go back to the app". The emails' real content is the 6-digit code, typed
/// into the app, so nothing depends on links opening the app. The Reset
/// password template tests `.RedirectTo` against this exact URL to tell the
/// app's request (code only) from the panel's (link), so it must be listed
/// in Supabase's Redirect URLs (docs/email-templates/README.md).
const kAuthEmailRedirect = 'https://papemosque.ca/hesap/onaylandi';

/// Length of the codes in the emails (Supabase: Email OTP Length).
const kEmailCodeLength = 6;

enum SignUpResult {
  /// "Confirm email" is off: the account is created and signed in.
  signedIn,

  /// A code was sent; the account is waiting for it.
  confirmEmail,

  /// The address already has an account. With "Confirm email" on, Supabase
  /// answers like a success and sends nothing, with an empty `identities`.
  alreadyRegistered,
}

/// Email/password accounts: sign-up, its code, and the password reset.
/// Screens go through [instance], so tests can replace it.
abstract class EmailAuth {
  static EmailAuth instance = SupabaseEmailAuth();

  Future<AuthError?> signIn(String email, String password);

  Future<({SignUpResult? result, AuthError? error})> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  });

  /// Confirms the sign-up with the emailed code; signs in on success.
  Future<AuthError?> verifySignUp(String email, String code);

  Future<AuthError?> resendSignUp(String email);

  /// Sends a reset code. Answers the same whether or not [email] has an
  /// account: only a rate limit or a network failure comes back.
  Future<AuthError?> requestPasswordReset(String email);

  /// Checks the reset code; signs in on success, so [setNewPassword] works.
  Future<AuthError?> verifyRecovery(String email, String code);

  Future<AuthError?> setNewPassword(String password);
}

class SupabaseEmailAuth implements EmailAuth {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<AuthError?> _run(Future<void> Function() call) async {
    try {
      await call();
      return null;
    } on AuthException catch (e) {
      return AuthService.errorFrom(e);
    } catch (_) {
      return (kind: AuthFailure.unexpected, serverMessage: null);
    }
  }

  @override
  Future<AuthError?> signIn(String email, String password) =>
      AuthService.signInWithEmail(email, password);

  @override
  Future<({SignUpResult? result, AuthError? error})> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    final dob =
        '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
    AuthResponse? response;
    final error = await _run(() async {
      response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kAuthEmailRedirect,
        data: {'full_name': fullName, 'phone': phone, 'date_of_birth': dob},
      );
    });
    if (error != null) {
      return error.kind == AuthFailure.emailTaken
          ? (result: SignUpResult.alreadyRegistered, error: null)
          : (result: null, error: error);
    }
    return (result: signUpResultOf(response!), error: null);
  }

  @override
  Future<AuthError?> verifySignUp(String email, String code) => _run(
        () => _auth.verifyOTP(email: email, token: code, type: OtpType.signup),
      );

  @override
  Future<AuthError?> resendSignUp(String email) => _run(
        () => _auth.resend(
          email: email,
          type: OtpType.signup,
          emailRedirectTo: kAuthEmailRedirect,
        ),
      );

  @override
  Future<AuthError?> requestPasswordReset(String email) async {
    final error = await _run(
      () => _auth.resetPasswordForEmail(email, redirectTo: kAuthEmailRedirect),
    );
    return resetRequestError(error);
  }

  @override
  Future<AuthError?> verifyRecovery(String email, String code) => _run(
        () => _auth.verifyOTP(email: email, token: code, type: OtpType.recovery),
      );

  @override
  Future<AuthError?> setNewPassword(String password) =>
      _run(() => _auth.updateUser(UserAttributes(password: password)));
}

/// What a sign-up's answer means. With "Confirm email" on, an address that
/// already has an account gets a made-up user with no identities.
SignUpResult signUpResultOf(AuthResponse response) {
  if (response.session != null) return SignUpResult.signedIn;
  final identities = response.user?.identities;
  if (identities != null && identities.isEmpty) {
    return SignUpResult.alreadyRegistered;
  }
  return SignUpResult.confirmEmail;
}

/// A reset request never tells whether the address has an account: only a
/// rate limit or a network failure is shown, anything else reads as sent.
AuthError? resetRequestError(AuthError? error) =>
    error != null &&
            (error.kind == AuthFailure.rateLimited ||
                error.kind == AuthFailure.network)
        ? error
        : null;

/// Digits only, the code's length.
bool isCompleteCode(String code) =>
    RegExp('^[0-9]{$kEmailCodeLength}\$').hasMatch(code);
