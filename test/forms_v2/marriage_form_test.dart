import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/forms_v2/marriage_form.dart';

/// pape-admin's shared test cases (supabase/tests/fixtures/marriage-forms.json,
/// copied as is): the forms the database and the panel accept or refuse, and
/// the answer checks the panel runs after decrypting.
final cases = jsonDecode(File('test/fixtures/marriage-forms.json').readAsStringSync()) as Map;

Map formNamed(String name) => ((cases['forms'] as List).firstWhere((f) => f['name'] == name) as Map)['form'] as Map;

void main() {
  group('form', () {
    for (final c in cases['forms'] as List) {
      test('${c['name']} → ${c['valid'] ? 'valid' : 'refused'}', () {
        expect(marriageFormValid(c['form']), c['valid']);
      });
    }
  });

  group('answers', () {
    for (final c in cases['answers'] as List) {
      test(c['name'] as String, () {
        final r = validateAnswers(formNamed(c['form'] as String), c['answers'] as Map, cases['today'] as String);
        expect(r.errors, equals(c['errors']));
        expect(r.clean, equals(c['clean']));
      });
    }
  });

  test('the seed form: parent details show only if a parent is in Canada', () {
    final f = formNamed('default seed');
    final background = (f['sections'] as List)[1] as Map;
    final fields = background['fields'] as List;
    final parents = fields[2] as Map;
    final options = parents['options'] as List;
    final name = (fields[3] as Map)['id'] as String;
    expect(isVisible(f, {parents['id']: (options[0] as Map)['id']}, name), isTrue);
    expect(isVisible(f, {parents['id']: (options[1] as Map)['id']}, name), isTrue);
    expect(isVisible(f, {parents['id']: (options[2] as Map)['id']}, name), isFalse);
    expect(isVisible(f, {}, name), isFalse);
  });

  test('helpers', () {
    expect(pickText({'tr': 'Ad', 'en': 'Name'}, 'fr'), 'Name');
    expect(pickText({'tr': 'Ad'}, 'en'), 'Ad');
    expect(ageOn('2008-11-19', '2026-11-18'), 17);
    expect(ageOn('2008-11-18', '2026-11-18'), 18);
    expect(ageOn('2000-02-29', '2026-02-28'), 25);
    expect(phoneNormalize('(416) 555-0101'), '+14165550101');
    expect(phoneNormalize('0416 555 0101'), isNull);
    expect(isIsoDate('2026-02-30'), isFalse);
  });
}
