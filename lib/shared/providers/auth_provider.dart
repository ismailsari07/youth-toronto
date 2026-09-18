import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenOrNull(
    data: (state) => state.session?.user,
  );
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    return await Supabase.instance.client
        .from('user_profiles')
        .select('full_name, notifications_enabled, created_at, phone, date_of_birth')
        .eq('user_id', user.id)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});
