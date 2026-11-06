import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/formatters.dart';

Map<String, String> _strings(String lang) {
  final raw = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
      as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in raw.entries)
      if (!key.startsWith('@')) key: value as String,
  };
}

/// The placeholders a message can print: `{name}`, not select/plural cases.
Set<String> _heads(String text) => {
      for (final m in RegExp(r'\{(\w+)[,}]').allMatches(text)) m[1]!,
    };

void main() {
  final en = _strings('en');
  final fr = _strings('fr');
  final tr = _strings('tr');

  test('French and Turkish have exactly the English keys', () {
    expect(fr.keys.toSet(), en.keys.toSet());
    expect(tr.keys.toSet(), en.keys.toSet());
  });

  test('every placeholder of a message exists in French', () {
    for (final MapEntry(:key, :value) in en.entries) {
      if (value.contains(', select,') || value.contains(', plural,')) continue;
      expect(_heads(fr[key]!), _heads(value), reason: key);
    }
  });

  test('French strings still in English are only the listed ones', () {
    const same = {
      'organisationName', 'city', 'hijriMonth2', 'hijriMonth7', 'hijriMonth9',
      'datePatternLong', 'datePatternShort', 'datePatternDayMonth',
      'datePatternMonthYear', 'date', 'notifications', 'languageAuto',
    'newsPhotoCount', // "photo" is the same word
      'versionLabel', 'photos', 'appVersion', 'regQuestions',
    };
    expect(
      {for (final k in en.keys) if (fr[k] == en[k]) k},
      same,
    );
  });

  test('Canadian French: no space before ? ! ;, no-break space before :', () {
    for (final MapEntry(:key, :value) in fr.entries) {
      expect(value, isNot(matches(r'[   ][?!;]')), reason: key);
      expect(value, isNot(matches(r' :')), reason: key);
    }
  });

  test('one word for one thing', () {
    final all = fr.values.join('\n');
    expect(all, isNot(contains('E-mail')));
    expect(all, isNot(contains('Iqamah')));
    expect(all, isNot(contains('Athan')));
    expect(all, isNot(contains('Dhuhr')));
    expect(fr['jumuah'], "Prière du vendredi (Joumou'a)");
  });

  group('French grammar in code', () {
    final l = lookupAppLocalizations(const Locale('fr'));

    test('views agree with the count', () {
      expect(l.regViews(1), 'Consulté par 1 personne');
      expect(l.regViews(30), 'Consulté par 30 personnes');
    });

    test('just now, not "0 minutes"', () {
      expect(timeAgo(l, DateTime.now()), "à l'instant");
    });

    test('28 days is a month, not "0 mois"', () {
      final ago = DateTime.now().subtract(const Duration(days: 28));
      expect(timeAgo(l, ago), 'il y a 1 mois');
    });
  });
}
