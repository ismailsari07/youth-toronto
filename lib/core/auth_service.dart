import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'social_auth.dart';

/// Why an auth call failed. The UI turns it into a sentence in the app's
/// language (`authErrorText`); Supabase's own messages are English only.
enum AuthFailure {
  invalidCredentials,
  emailTaken,
  weakPassword,
  emailNotConfirmed,
  rateLimited,
  network,
  sessionExpired,
  adminAccount,
  deleteFailed,
  /// The user closed the Apple or Google sheet: show nothing.
  cancelled,
  /// Apple or Google couldn't complete the sign-in.
  providerFailed,
  /// Deleting an Apple account was confirmed with a different Apple ID.
  appleMismatch,
  /// delete-account needs a fresh Apple code (handled inside deleteAccount).
  appleReauthRequired,
  unexpected,
}

/// Outcome of set_my_initial_name().
enum InitialNameResult {
  saved,
  /// The name was already set (or there's no member row): nothing to do.
  notNeeded,
  invalid,
  failed,
}

/// delete-account's answer → why it failed (see the function's handler.ts).
AuthFailure deleteFailureFor(int status, Object? details) {
  final code = details is Map ? details['error'] : null;
  return switch ((status, code)) {
    (401, _) => AuthFailure.sessionExpired,
    (409, 'admin_account') => AuthFailure.adminAccount,
    (409, 'apple_mismatch') => AuthFailure.appleMismatch,
    (428, 'apple_reauth_required') => AuthFailure.appleReauthRequired,
    _ => AuthFailure.deleteFailed,
  };
}

/// [serverMessage] is Supabase's English text, kept for failures this app
/// has no sentence of its own for.
typedef AuthError = ({AuthFailure kind, String? serverMessage});

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;

  static Future<AuthError?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return _fromAuthException(e);
    } catch (_) {
      return (kind: AuthFailure.unexpected, serverMessage: null);
    }
  }

  static Future<AuthError?> signUpWithEmail(
    String email,
    String password,
    String fullName, {
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      final dob =
          '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone, 'date_of_birth': dob},
      );
      return null;
    } on AuthException catch (e) {
      return _fromAuthException(e);
    } catch (_) {
      return (kind: AuthFailure.unexpected, serverMessage: null);
    }
  }

  /// Native Sign in with Apple (iOS). The nonce's hash goes to Apple, the
  /// raw value to Supabase. Apple sends the name only on the first
  /// authorization; it is saved with set_my_initial_name(), kept in the
  /// Keychain until that succeeds.
  static Future<AuthError?> signInWithApple() async {
    final rawNonce = generateRawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashNonce(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      return _providerError(e.code == AuthorizationErrorCode.canceled);
    } catch (_) {
      return _providerError(false);
    }
    final idToken = credential.identityToken;
    if (idToken == null) return _providerError(false);

    final AuthResponse response;
    try {
      response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on AuthException catch (e) {
      return _fromAuthException(e);
    } catch (_) {
      return (kind: AuthFailure.network, serverMessage: null);
    }

    final userId = response.user?.id;
    final name = appleFullName(credential.givenName, credential.familyName);
    if (userId != null && name != null) {
      await PendingAppleName.save(userId, name);
      await flushPendingName();
    }
    return null;
  }

  /// Native Google sign-in (iOS). The client IDs come from Info.plist
  /// (GIDClientID, GIDServerClientID). A fresh nonce per sign-in, as for
  /// Apple: initialize() only stores it, so calling it each time is fine.
  static Future<AuthError?> signInWithGoogle() async {
    final rawNonce = generateRawNonce();
    final String? idToken;
    try {
      final google = GoogleSignIn.instance;
      await google.initialize(nonce: hashNonce(rawNonce));
      final account = await google.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      return _providerError(e.code == GoogleSignInExceptionCode.canceled);
    } catch (_) {
      return _providerError(false);
    }
    if (idToken == null) return _providerError(false);

    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: rawNonce,
      );
      return null;
    } on AuthException catch (e) {
      return _fromAuthException(e);
    } catch (_) {
      return (kind: AuthFailure.network, serverMessage: null);
    }
  }

  static AuthError _providerError(bool cancelled) => (
        kind: cancelled ? AuthFailure.cancelled : AuthFailure.providerFailed,
        serverMessage: null,
      );

  /// Sets the signed-in member's name once, while it is still the automatic
  /// one (set_my_initial_name; "İsim ekle" and the first Apple sign-in).
  static Future<InitialNameResult> setInitialName(String name) async {
    try {
      await _client.rpc(
        'set_my_initial_name',
        params: {'p_full_name': name},
      );
      return InitialNameResult.saved;
    } on PostgrestException catch (e) {
      return switch (e.code) {
        'P0001' || 'P0002' => InitialNameResult.notNeeded,
        '22023' => InitialNameResult.invalid,
        _ => InitialNameResult.failed,
      };
    } catch (_) {
      return InitialNameResult.failed;
    }
  }

  /// Sends a name Apple gave that hasn't been saved yet (after an Apple
  /// sign-in, and at launch). Returns true when it saved one.
  static Future<bool> flushPendingName() async {
    var saved = false;
    await PendingAppleName.flush(currentUser?.id, (name) async {
      final result = await setInitialName(name);
      saved = result == InitialNameResult.saved;
      return result != InitialNameResult.failed;
    });
    return saved;
  }

  static bool get _usedGoogle {
    final providers = currentUser?.appMetadata['providers'];
    return providers is List && providers.contains('google');
  }

  static AuthError _fromAuthException(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return (kind: AuthFailure.network, serverMessage: null);
    }
    final kind = switch (e.code) {
      'invalid_credentials' => AuthFailure.invalidCredentials,
      'user_already_exists' || 'email_exists' => AuthFailure.emailTaken,
      'weak_password' => AuthFailure.weakPassword,
      'email_not_confirmed' => AuthFailure.emailNotConfirmed,
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        AuthFailure.rateLimited,
      _ when e.message == 'Invalid login credentials' =>
        AuthFailure.invalidCredentials,
      _ => AuthFailure.unexpected,
    };
    return (kind: kind, serverMessage: e.message);
  }

  static Future<void> signOut() async {
    final google = _usedGoogle;
    await _client.auth.signOut();
    // So the next Google sign-in shows the account picker.
    if (google) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  /// Permanently deletes the signed-in user's account via the
  /// `delete-account` Edge Function (which holds the service-role key).
  /// Returns null on success, else why it failed. On success the local
  /// session is cleared, so the UI falls back to the signed-out state.
  ///
  /// An account with a Sign in with Apple identity first gets 428: Apple
  /// then asks the user to confirm once more, and the fresh authorization
  /// code lets the function revoke the Apple tokens (App Review 5.1.1(v))
  /// before it deletes anything. Admins get their 409 before that.
  static Future<AuthError?> deleteAccount() async {
    final google = _usedGoogle;
    var error = await _invokeDelete(null);
    if (error?.kind == AuthFailure.appleReauthRequired) {
      final String code;
      try {
        final credential =
            await SignInWithApple.getAppleIDCredential(scopes: const []);
        code = credential.authorizationCode;
      } on SignInWithAppleAuthorizationException catch (e) {
        return _providerError(e.code == AuthorizationErrorCode.canceled);
      } catch (_) {
        return _providerError(false);
      }
      error = await _invokeDelete({'apple_authorization_code': code});
    }
    if (error != null) return error;

    await _signOutLocally();
    await PendingAppleName.clear();
    if (google) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
    return null;
  }

  static Future<AuthError?> _invokeDelete(Map<String, String>? body) async {
    try {
      await _client.functions.invoke('delete-account', body: body);
      return null;
    } on FunctionException catch (e) {
      final kind = deleteFailureFor(e.status, e.details);
      if (kind == AuthFailure.sessionExpired) await _signOutLocally();
      return (kind: kind, serverMessage: null);
    } catch (_) {
      // No response. The server may still have deleted the account (reply
      // lost), so ask it: if the user no longer exists, deletion succeeded.
      if (await _userIsGone()) return null;
      return (kind: AuthFailure.network, serverMessage: null);
    }
  }

  static Future<bool> _userIsGone() async {
    try {
      await _client.auth.getUser();
      return false;
    } on AuthException catch (e) {
      // Only a definite "no such user" counts; any other failure (including
      // network) means we can't tell, so the account is treated as intact.
      return e.code == 'user_not_found';
    } catch (_) {
      return false;
    }
  }

  /// Clears this device's session only; after deletion there is no server
  /// session to revoke.
  static Future<void> _signOutLocally() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Local sign-out clears storage even if the server call fails.
    }
  }
}
