import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'registration_state.dart';

/// What a failed `register_for_event` means for the app (pape-admin
/// CLAUDE.md §10.4). PostgREST errors carry the SQLSTATE in `code`, the key
/// in `message` and, for invalid_answers, JSON in `details`.
sealed class RegisterFailure {
  const RegisterFailure();

  static RegisterFailure of(Object error) {
    if (error is! PostgrestException) return const RegisterOffline();
    return switch ((error.code, error.message)) {
      ('42501', _) => const RegisterNeedsSignIn(),
      ('P0002', 'no_profile') => const RegisterNoProfile(),
      ('P0002', _) => const RegisterNotAccepting(),
      ('P0001', 'registration_closed') => const RegisterStateChanged(RegStatus.closed),
      ('P0001', 'deadline_passed') => const RegisterStateChanged(RegStatus.deadlinePassed),
      ('P0001', 'full') => const RegisterStateChanged(RegStatus.full),
      ('P0001', 'form_changed') => const RegisterFormChanged(),
      ('P0001', 'registration_unavailable') => const RegisterUnavailable(),
      ('22023', 'invalid_answers') => RegisterInvalid(parseDetails(error.details)),
      _ => const RegisterOffline(),
    };
  }

  /// `{question id | "full_name" | "phone" | "_answers": code}`. Unreadable
  /// details become `_answers`, so the screen still says something.
  static Map<String, String> parseDetails(Object? raw) {
    try {
      final map = raw is String ? jsonDecode(raw) : raw;
      if (map is Map && map.isNotEmpty) {
        return {
          for (final MapEntry(:key, :value) in map.entries)
            '$key': value is String ? value : 'wrong_type',
        };
      }
    } catch (_) {
      /* not JSON */
    }
    return const {'_answers': 'wrong_type'};
  }
}

/// 42501: the session is gone. Sign in, then send again.
class RegisterNeedsSignIn extends RegisterFailure {
  const RegisterNeedsSignIn();
}

/// P0002 event_not_found: unpublished, deleted or no form any more.
class RegisterNotAccepting extends RegisterFailure {
  const RegisterNotAccepting();
}

/// P0002 no_profile: a panel account without a member profile (D2).
class RegisterNoProfile extends RegisterFailure {
  const RegisterNoProfile();
}

/// P0001 registration_closed / deadline_passed / full.
class RegisterStateChanged extends RegisterFailure {
  const RegisterStateChanged(this.status);

  final RegStatus status;
}

/// P0001 form_changed: refetch, keep what still fits, send again.
class RegisterFormChanged extends RegisterFailure {
  const RegisterFormChanged();
}

/// P0001 registration_unavailable: the kill switch went off.
class RegisterUnavailable extends RegisterFailure {
  const RegisterUnavailable();
}

/// 22023 invalid_answers: one code per field, all at once.
class RegisterInvalid extends RegisterFailure {
  const RegisterInvalid(this.fields);

  final Map<String, String> fields;
}

/// No answer, or anything unexpected. Nothing was saved (or, if it was,
/// sending again answers `already: true`).
class RegisterOffline extends RegisterFailure {
  const RegisterOffline();
}
