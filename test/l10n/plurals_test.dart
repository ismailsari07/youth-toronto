import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final tr = lookupAppLocalizations(const Locale('tr'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  test('one viewer is one person', () {
    expect(en.regViews(1), '1 person viewed');
    expect(en.regViews(30), '30 people viewed');
    expect(fr.regViews(1), 'Consulté par 1 personne');
    expect(tr.regViews(1), '1 kişi görüntüledi');
  });

  test('every count reads right at 1 and at 2', () {
    expect(
      [en.minutesAgo(1), en.hoursAgo(1), en.daysAgo(1), en.weeksAgo(1), en.monthsAgo(1), en.inDays(1), en.regPlacesLeft(1)],
      ['1 minute ago', '1 hour ago', '1 day ago', '1 week ago', '1 month ago', '1 day', 'Last place'],
    );
    expect(
      [en.minutesAgo(2), en.hoursAgo(2), en.daysAgo(2), en.weeksAgo(2), en.monthsAgo(2), en.inDays(2), en.regPlacesLeft(2)],
      ['2 minutes ago', '2 hours ago', '2 days ago', '2 weeks ago', '2 months ago', '2 days', 'Last 2 places'],
    );
    expect(
      [fr.minutesAgo(1), fr.hoursAgo(1), fr.daysAgo(1), fr.weeksAgo(1), fr.monthsAgo(1), fr.inDays(1), fr.regPlacesLeft(1)],
      ['il y a 1 minute', 'il y a 1 heure', 'il y a 1 jour', 'il y a 1 semaine', 'il y a 1 mois', '1 jour', 'Dernière place'],
    );
    expect(
      [fr.minutesAgo(2), fr.hoursAgo(2), fr.daysAgo(2), fr.weeksAgo(2), fr.monthsAgo(2), fr.inDays(2), fr.regPlacesLeft(2)],
      ['il y a 2 minutes', 'il y a 2 heures', 'il y a 2 jours', 'il y a 2 semaines', 'il y a 2 mois', '2 jours', '2 dernières places'],
    );
  });

  // Turkish nouns don't change after a number ("1 kişi", "30 kişi").
  for (final lang in const ['en', 'fr']) {
    test('$lang: no message prints a count without a plural form', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
        final placeholders = (en['@$key'] as Map?)?['placeholders'] as Map?;
        if (placeholders == null) continue;
        for (final MapEntry(key: name, value: spec) in placeholders.entries) {
          if ((spec as Map)['type'] != 'int') continue;
          expect(arb[key], contains('{$name, plural,'), reason: '$lang $key');
        }
      }
    });
  }
}
