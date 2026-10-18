import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/registration/registration_api.dart';
import '../../core/registration/registration_state.dart';
import 'auth_provider.dart';
import 'push_provider.dart';

/// In-app event registration (pape-admin CLAUDE.md §10). Everything here
/// lives in memory only: the state holds the member's details, and nothing
/// of it is written to disk.

final registrationApiProvider =
    Provider<RegistrationApi>((ref) => const SupabaseRegistrationApi());

/// The push identity for the registration RPCs (null where push isn't
/// supported). A provider so tests can swap it.
final deviceCredentialsProvider = Provider<Future<DeviceCredentials?> Function()>(
  (ref) => () => ref.read(pushProvider.notifier).credentials(),
);

/// The member's id, or null: the state is fetched again whenever it
/// changes (sign-in, sign-out), but not on a token refresh.
final _memberIdProvider =
    Provider<String?>((ref) => ref.watch(currentUserProvider.select((u) => u?.id)));

/// `event_registration_state` for one event. Always the source of the form
/// and its version (never the list row). Dropped when the page closes.
final registrationStateProvider =
    FutureProvider.autoDispose.family<RegistrationState, String>((ref, eventId) {
  ref.watch(_memberIdProvider);
  return ref.read(registrationApiProvider).state(eventId);
});

/// "X kişi görüntüledi": recorded once per event per app session (kept
/// alive), best effort: any error, or no device yet, shows nothing.
final eventViewsProvider = FutureProvider.family<int?, String>((ref, eventId) async {
  try {
    final device = await ref.read(deviceCredentialsProvider)();
    if (device == null) return null;
    return await ref.read(registrationApiProvider).recordView(eventId, device);
  } catch (_) {
    return null;
  }
});

/// What the member typed, per event, so backing out of the form and coming
/// back keeps it (D8). Memory only; cleared on success and on sign-out, and
/// gone when the app closes.
@immutable
class RegistrationDraft {
  const RegistrationDraft({
    this.answers = const {},
    this.fullName,
    this.phone,
  });

  final Map<String, Object?> answers;
  final String? fullName;
  final String? phone;

  RegistrationDraft copyWith({
    Map<String, Object?>? answers,
    String? fullName,
    String? phone,
  }) =>
      RegistrationDraft(
        answers: answers ?? this.answers,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
      );
}

final registrationDraftsProvider =
    NotifierProvider<RegistrationDrafts, Map<String, RegistrationDraft>>(
  RegistrationDrafts.new,
);

class RegistrationDrafts extends Notifier<Map<String, RegistrationDraft>> {
  @override
  Map<String, RegistrationDraft> build() {
    // Another member must never see these answers.
    ref.watch(_memberIdProvider);
    return const {};
  }

  RegistrationDraft of(String eventId) => state[eventId] ?? const RegistrationDraft();

  void save(String eventId, RegistrationDraft draft) =>
      state = {...state, eventId: draft};

  void clear(String eventId) => state = {...state}..remove(eventId);
}
