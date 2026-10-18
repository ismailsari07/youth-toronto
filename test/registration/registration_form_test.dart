import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/registration/registration_form.dart';

/// pape-admin's shared fixture (supabase/tests/fixtures/registration-forms.json,
/// copied as is): the forms the server and the panel accept or refuse.
final fixtures = (jsonDecode(
  File('test/fixtures/registration-forms.json').readAsStringSync(),
) as Map)['forms'] as List;

Map<String, dynamic> fixture(String name) =>
    (fixtures.firstWhere((f) => f['name'] == name) as Map).cast<String, dynamic>();

/// The server's event_form_signature(), from what the app parsed: the same
/// string means the app read every id, type, flag, bound and option.
String signature(List<Question> qs) => qs.map((q) {
      String n(num? v) => v == null
          ? ''
          : v == v.truncate()
              ? v.toInt().toString()
              : v.toString();
      return [
        q.id,
        q.type.wire,
        q.required ? '1' : '0',
        n(q.min),
        n(q.max),
        q.type == QuestionType.number ? (q.integer ? '1' : '0') : '',
        q.options.map((o) => o.id).join(','),
      ].join(':');
    }).join(';');

Question q(
  String id,
  QuestionType type, {
  bool required = false,
  num? min,
  num? max,
  bool integer = false,
  List<String> options = const [],
}) =>
    Question(
      id: id,
      type: type,
      required: required,
      label: const {'tr': 'Soru'},
      min: min,
      max: max,
      integer: integer,
      options: [for (final o in options) ChoiceOption(o, {'tr': o})],
    );

void main() {
  group('the shared fixture', () {
    for (final f in fixtures.where((f) => f['valid'] == true)) {
      test('valid form "${f['name']}" parses to the server\'s signature', () {
        final qs = Question.parseForm(f['form']);
        expect(signature(qs), f['signature']);
        expect(qs.every((q) => q.type != QuestionType.unknown), isTrue);
      });
    }

    test('"every type" has all eight types, in order', () {
      final qs = Question.parseForm(fixture('every type')['form']);
      expect(qs.map((q) => q.type).toSet(), {
        for (final t in QuestionType.values)
          if (t != QuestionType.unknown) t,
      });
    });

    test('a type this version does not know is kept as unknown', () {
      final qs = Question.parseForm(fixture('unknown type (file)')['form']);
      expect(qs.map((q) => q.type), contains(QuestionType.unknown));
    });
  });

  group('labels', () {
    const label = {'tr': 'Seviye', 'en': 'Level'};
    test('device language, then English, then Turkish', () {
      expect(pickLabel(label, 'en'), 'Level');
      expect(pickLabel(label, 'fr'), 'Level');
      expect(pickLabel(label, 'tr'), 'Seviye');
      expect(pickLabel({'tr': 'Kur’an', 'fr': 'Coran'}, 'fr'), 'Coran');
      expect(pickLabel({'tr': 'Kur’an', 'fr': 'Coran'}, 'en'), 'Kur’an');
    });

    test('blank or missing is skipped; nothing gives ""', () {
      expect(pickLabel({'tr': 'A', 'en': ' '}, 'en'), 'A');
      expect(pickLabel(null, 'tr'), '');
    });
  });

  test('number: a missing integer key means decimals (D1)', () {
    final parsed = Question.parse({
      'id': 'q_AAAAAAA2',
      'type': 'number',
      'required': false,
      'label': {'tr': 'x'},
    })!;
    expect(parsed.integer, isFalse);
  });

  group('payload', () {
    final qs = [
      q('t', QuestionType.shortText),
      q('n', QuestionType.number),
      q('m', QuestionType.multipleChoice, options: ['o1', 'o2', 'o3']),
      q('y', QuestionType.yesNo),
      q('e', QuestionType.longText),
      q('u', QuestionType.unknown),
    ];

    test('answered only, trimmed, choices in the form order, false kept', () {
      expect(
        answersPayload(qs, {
          't': '  Ali ',
          'n': 2.5,
          'm': ['o3', 'o1'],
          'y': false,
          'e': '   ',
          'u': 'x',
        }),
        {'t': 'Ali', 'n': 2.5, 'm': ['o1', 'o3'], 'y': false},
      );
    });

    test('empty list and null are left out', () {
      expect(answersPayload(qs, {'m': <String>[], 't': null}), isEmpty);
    });
  });

  test('form_changed keeps answers whose id and type still fit', () {
    final fresh = [
      q('t', QuestionType.shortText),
      q('c', QuestionType.singleChoice, options: ['o1']),
      q('m', QuestionType.multipleChoice, options: ['o1', 'o2']),
      q('n', QuestionType.shortText), // was a number
    ];
    expect(
      keepAnswers({
        't': 'Ali',
        'c': 'o9', // option removed
        'm': ['o1', 'o2'],
        'n': 3,
        'gone': 'x',
      }, fresh),
      {'t': 'Ali', 'm': ['o1', 'o2']},
    );
  });

  group('local checks give the server\'s codes', () {
    final qs = [
      q('req', QuestionType.shortText, required: true),
      q('short', QuestionType.shortText),
      q('long', QuestionType.longText),
      q('int', QuestionType.number, min: 1, max: 6, integer: true),
      q('dec', QuestionType.number),
      q('date', QuestionType.date),
      q('tel', QuestionType.phone),
      q('one', QuestionType.singleChoice, options: ['o1']),
      q('yn', QuestionType.yesNo, required: true),
    ];

    test('everything wrong at once', () {
      expect(
        localErrors(qs, {
          'short': 'x' * 201,
          'long': 'x' * 2001,
          'int': 2.5,
          'dec': 'abc',
          'date': '2026-02-30',
          'tel': '555-0101',
          'one': 'o9',
        }, fullName: '  ', phone: '12'),
        {
          'full_name': 'required',
          'phone': 'invalid',
          'req': 'required',
          'short': 'too_long',
          'long': 'too_long',
          'int': 'not_an_integer',
          'dec': 'not_a_number',
          'date': 'invalid_date',
          'tel': 'invalid_phone',
          'one': 'unknown_option',
          'yn': 'required',
        },
      );
    });

    test('ranges, decimals, dates', () {
      expect(localErrors(qs, {'int': 7, 'req': 'a', 'yn': true}), {'int': 'out_of_range'});
      expect(localErrors(qs, {'dec': 1.1234567, 'req': 'a', 'yn': true}), {'dec': 'out_of_range'});
      expect(localErrors(qs, {'dec': 1.123456, 'req': 'a', 'yn': true}), isEmpty);
      expect(localErrors(qs, {'date': '1899-12-31', 'req': 'a', 'yn': true}), {'date': 'invalid_date'});
      expect(localErrors(qs, {'date': '2024-02-29', 'req': 'a', 'yn': true}), isEmpty);
    });

    test('a required yes/no means answered, not yes', () {
      expect(localErrors(qs, {'req': 'a', 'yn': false}), isEmpty);
    });

    test('name over 120 characters; phone missing', () {
      expect(localErrors(const [], const {}, fullName: 'a' * 121), {'full_name': 'invalid'});
      expect(localErrors(const [], const {}, phone: ' '), {'phone': 'required'});
    });
  });

  test('phone normalising matches the server (event_registration.sql cases)', () {
    const cases = {
      '(416) 555-0101': '+14165550101',
      '416.555.0101': '+14165550101',
      '1 416 555 0101': '+14165550101',
      '+90 532 123 45 67': '+905321234567',
      '+33 6 12 34 56 78': '+33612345678',
      '555-0101': null,
      'abc': null,
      '0416 555 0101': null,
      '+0 123 4567 890': null,
      '': null,
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(normalizePhone(key), value, reason: key);
    }
  });

  test('a required question of an unknown type blocks sending (D6)', () {
    expect(needsUpdate([q('a', QuestionType.unknown)]), isFalse);
    expect(needsUpdate([q('a', QuestionType.unknown, required: true)]), isTrue);
  });
}
