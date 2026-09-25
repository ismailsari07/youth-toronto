import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;

  static Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  static Future<String?> signUpWithEmail(
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
      return e.message;
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Permanently deletes the signed-in user's account via the
  /// `delete-account` Edge Function (which holds the service-role key).
  /// Returns null on success, else a message to show. On success the local
  /// session is cleared, so the UI falls back to the signed-out state.
  static Future<String?> deleteAccount() async {
    try {
      await _client.functions.invoke('delete-account');
      await _signOutLocally();
      return null;
    } on FunctionException catch (e) {
      if (e.status == 401) {
        await _signOutLocally();
        return 'Your session has expired. Sign in again, then retry.';
      }
      final details = e.details;
      if (e.status == 409 &&
          details is Map &&
          details['error'] == 'admin_account') {
        return "Admin accounts can't be deleted from the app. "
            'Contact another administrator.';
      }
      return "Couldn't delete your account. Please try again.";
    } catch (_) {
      // No response. The server may still have deleted the account (reply
      // lost), so ask it: if the user no longer exists, deletion succeeded.
      if (await _userIsGone()) {
        await _signOutLocally();
        return null;
      }
      return "Couldn't reach the server. Check your connection and try again.";
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
