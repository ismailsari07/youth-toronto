import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/registration/registration_errors.dart';
import 'package:myt_flutter/core/registration/registration_form.dart';
import 'package:myt_flutter/core/registration/registration_state.dart';
import 'package:myt_flutter/features/registration/registration_text.dart';
import 'package:myt_flutter/l10n/app_localizations_en.dart';
import 'package:myt_flutter/l10n/app_localizations_fr.dart';
import 'package:myt_flutter/l10n/app_localizations_tr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PostgrestException pg(String code, String message, [Object? details]) =>
    PostgrestException(code: code, message: message, details: details);

void main() {
  group('register_for_event errors (§10.4)', () {
    test('every code and message', () {
      expect(RegisterFailure.of(pg('42501', 'not signed in')), isA<RegisterNeedsSignIn>());
      expect(RegisterFailure.of(pg('P0002', 'event_not_found')), isA<RegisterNotAccepting>());
      expect(RegisterFailure.of(pg('P0002', 'no_profile')), isA<RegisterNoProfile>());
      for (final (message, status) in [
        ('registration_closed', RegStatus.closed),
        ('deadline_passed', RegStatus.deadlinePassed),
        ('full', RegStatus.full),
      ]) {
        final f = RegisterFailure.of(pg('P0001', message));
        expect((f as RegisterStateChanged).status, status, reason: message);
      }
      expect(RegisterFailure.of(pg('P0001', 'form_changed')), isA<RegisterFormChanged>());
      expect(RegisterFailure.of(pg('P0001', 'registration_unavailable')), isA<RegisterUnavailable>());
    });

    test('anything else, and no answer, is offline', () {
      expect(RegisterFailure.of(pg('P0001', 'something_new')), isA<RegisterOffline>());
      expect(RegisterFailure.of(Exception('socket')), isA<RegisterOffline>());
    });

    test('invalid_answers: details as JSON text or as a map', () {
      const raw = '{"q_AAAAAAA2": "required", "full_name": "required", "phone": "invalid"}';
      final f = RegisterFailure.of(pg('22023', 'invalid_answers', raw)) as RegisterInvalid;
      expect(f.fields, {'q_AAAAAAA2': 'required', 'full_name': 'required', 'phone': 'invalid'});
      final m = RegisterFailure.of(pg('22023', 'invalid_answers', {'_answers': 'too_long'}))
          as RegisterInvalid;
      expect(m.fields, {'_answers': 'too_long'});
    });

    test('unreadable details still say something', () {
      expect(RegisterFailure.parseDetails('not json'), {'_answers': 'wrong_type'});
      expect(RegisterFailure.parseDetails(null), {'_answers': 'wrong_type'});
      expect(RegisterFailure.parseDetails({'q_X': 5}), {'q_X': 'wrong_type'});
    });
  });

  group('texts under the field', () {
    const codes = [
      'required', 'wrong_type', 'too_long', 'not_a_number', 'not_an_integer',
      'out_of_range', 'unknown_option', 'invalid_date', 'invalid_phone', 'unknown_question',
    ];

    for (final l in [AppLocalizationsTr(), AppLocalizationsEn(), AppLocalizationsFr()]) {
      test('${l.localeName}: every code has a text', () {
        for (final code in codes) {
          expect(registrationErrorText(l, 'q_AAAAAAA2', code), isNotEmpty, reason: code);
        }
        for (final field in ['full_name', 'phone']) {
          for (final code in ['required', 'invalid']) {
            expect(registrationErrorText(l, field, code), isNotEmpty);
          }
        }
      });
    }

    test('name and phone have their own sentences', () {
      final l = AppLocalizationsTr();
      expect(registrationErrorText(l, 'full_name', 'required'), 'Adını yaz.');
      expect(registrationErrorText(l, 'phone', 'required'), 'Telefon numaranı yaz.');
      expect(registrationErrorText(l, 'q_A', 'required'), 'Bu soru zorunlu.');
      expect(registrationErrorText(l, 'phone', 'invalid'),
          registrationErrorText(l, 'q_A', 'invalid_phone'));
    });

    test('our own mistakes ask for an update, not a correction', () {
      final l = AppLocalizationsEn();
      expect(registrationErrorText(l, 'q_A', 'wrong_type'), l.regErrRejected);
      expect(registrationErrorText(l, 'q_A', 'unknown_question'), l.regErrRejected);
      expect(registrationErrorText(l, 'q_A', 'brand_new_code'), l.regErrRejected);
    });
  });

  group('event_registration_state', () {
    Map<String, dynamic> base({Object? status = 'open', Object? me}) => {
          'form': {
            'questions': [
              {'id': 'q_AAAAAAA2', 'type': 'yes_no', 'required': true, 'label': {'tr': 'Servis?'}},
            ],
          },
          'form_version': 'abc123def456',
          'status': status,
          'deadline': '2026-11-06T23:59:00+00:00',
          'places_left': 3,
          'require_phone': true,
          'available': true,
          'me': me,
        };

    test('signed out', () {
      final s = RegistrationState.fromJson(base());
      expect(s.me, isNull);
      expect(s.status, RegStatus.open);
      expect(s.formVersion, 'abc123def456');
      expect(s.placesLeft, 3);
      expect(s.deadline, DateTime.utc(2026, 11, 6, 23, 59));
      expect(s.questions.single.type, QuestionType.yesNo);
    });

    test('a member with a registration', () {
      final s = RegistrationState.fromJson(base(
        status: 'registered',
        me: {
          'has_profile': true,
          'full_name': 'Zeynep Aksoy',
          'name_missing': false,
          'email': '',
          'phone': null,
          'phone_missing': true,
          'registration': {
            'created_at': '2026-10-18T18:05:00+00:00',
            'full_name': 'Zeynep Aksoy',
            'phone': '+14165550123',
            'answers': {'q_AAAAAAA2': false},
          },
        },
      ));
      expect(s.registered, isTrue);
      expect(s.me!.email, '');
      expect(s.me!.registration!.answers, {'q_AAAAAAA2': false});
    });

    test('a panel account without a member profile', () {
      final s = RegistrationState.fromJson(base(me: {'has_profile': false, 'registration': null}));
      expect(s.me!.hasProfile, isFalse);
    });

    test('statuses, including one this version does not know (D6)', () {
      for (final (raw, status) in [
        ('full', RegStatus.full),
        ('deadline_passed', RegStatus.deadlinePassed),
        ('closed', RegStatus.closed),
        ('waitlist', RegStatus.closed),
      ]) {
        expect(RegistrationState.fromJson(base(status: raw)).status, status);
      }
    });

    test('kill switch', () {
      expect(RegistrationState.fromJson({...base(), 'available': false}).available, isFalse);
    });
  });
}
