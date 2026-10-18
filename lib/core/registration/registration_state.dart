import 'package:flutter/foundation.dart';

import 'registration_form.dart';

/// `event_registration_state` (pape-admin CLAUDE.md §10.1): everything the
/// event page needs. Never cached on disk: it holds the member's details.

enum RegStatus {
  open,
  full,
  deadlinePassed,

  /// Closed by an admin, and any status this version doesn't know (D6).
  closed,
  registered;

  static RegStatus parse(Object? raw) => switch (raw) {
        'open' => open,
        'full' => full,
        'deadline_passed' => deadlinePassed,
        'registered' => registered,
        _ => closed,
      };
}

/// The member's own copy, for "Gönderdiğin bilgiler".
@immutable
class MyRegistration {
  const MyRegistration({
    required this.createdAt,
    required this.fullName,
    this.phone,
    this.answers = const {},
  });

  final DateTime createdAt;
  final String fullName;
  final String? phone;
  final Map<String, dynamic> answers;
}

/// The signed-in member, as the server sees them.
@immutable
class RegistrationMe {
  const RegistrationMe({
    required this.hasProfile,
    this.fullName = '',
    this.nameMissing = false,
    this.email = '',
    this.phone,
    this.phoneMissing = true,
    this.registration,
  });

  /// False: a panel account without a member profile (can't register).
  final bool hasProfile;
  final String fullName;

  /// Still the automatic name: asked on the form, saved with the
  /// registration.
  final bool nameMissing;

  /// May be '' (then hidden).
  final String email;
  final String? phone;
  final bool phoneMissing;
  final MyRegistration? registration;
}

@immutable
class RegistrationState {
  const RegistrationState({
    required this.questions,
    required this.formVersion,
    required this.status,
    this.deadline,
    this.placesLeft,
    this.requirePhone = false,
    this.available = true,
    this.me,
  });

  final List<Question> questions;

  /// Sent back with the registration; a changed form answers form_changed.
  final String formVersion;
  final RegStatus status;

  /// The effective deadline; null for a recurring event without one.
  final DateTime? deadline;

  /// Only while open and 5 or fewer places remain.
  final int? placesLeft;
  final bool requirePhone;

  /// False: the kill switch is off.
  final bool available;

  /// Null when signed out.
  final RegistrationMe? me;

  bool get registered => status == RegStatus.registered;

  factory RegistrationState.fromJson(Map<String, dynamic> j) {
    final me = j['me'];
    return RegistrationState(
      questions: Question.parseForm(j['form']),
      formVersion: j['form_version'] as String? ?? '',
      status: RegStatus.parse(j['status']),
      deadline: DateTime.tryParse(j['deadline'] as String? ?? ''),
      placesLeft: (j['places_left'] as num?)?.toInt(),
      requirePhone: j['require_phone'] == true,
      available: j['available'] != false,
      me: me is Map ? _me(me.cast<String, dynamic>()) : null,
    );
  }

  static RegistrationMe _me(Map<String, dynamic> m) {
    final reg = m['registration'];
    return RegistrationMe(
      hasProfile: m['has_profile'] == true,
      fullName: m['full_name'] as String? ?? '',
      nameMissing: m['name_missing'] == true,
      email: m['email'] as String? ?? '',
      phone: m['phone'] as String?,
      phoneMissing: m['phone_missing'] != false,
      registration: reg is Map && DateTime.tryParse('${reg['created_at']}') != null
          ? MyRegistration(
              createdAt: DateTime.parse('${reg['created_at']}'),
              fullName: reg['full_name'] as String? ?? '',
              phone: reg['phone'] as String?,
              answers: reg['answers'] is Map
                  ? (reg['answers'] as Map).cast<String, dynamic>()
                  : const {},
            )
          : null,
    );
  }
}
