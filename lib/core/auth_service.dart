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
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone, 'date_of_birth': dob},
      );
      // ignore: avoid_print
      print('auth sign up response: ${response.user?.id}');
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
}
