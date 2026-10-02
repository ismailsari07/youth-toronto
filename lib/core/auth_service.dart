import 'package:supabase_flutter/supabase_flutter.dart';

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
  unexpected,
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
    await _client.auth.signOut();
  }

  /// Permanently deletes the signed-in user's account via the
  /// `delete-account` Edge Function (which holds the service-role key).
  /// Returns null on success, else why it failed. On success the local
  /// session is cleared, so the UI falls back to the signed-out state.
  static Future<AuthError?> deleteAccount() async {
    try {
      await _client.functions.invoke('delete-account');
      await _signOutLocally();
      return null;
    } on FunctionException catch (e) {
      if (e.status == 401) {
        await _signOutLocally();
        return (kind: AuthFailure.sessionExpired, serverMessage: null);
      }
      final details = e.details;
      if (e.status == 409 &&
          details is Map &&
          details['error'] == 'admin_account') {
        return (kind: AuthFailure.adminAccount, serverMessage: null);
      }
      return (kind: AuthFailure.deleteFailed, serverMessage: null);
    } catch (_) {
      // No response. The server may still have deleted the account (reply
      // lost), so ask it: if the user no longer exists, deletion succeeded.
      if (await _userIsGone()) {
        await _signOutLocally();
        return null;
      }
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
