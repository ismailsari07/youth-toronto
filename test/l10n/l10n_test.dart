import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/formatters.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final tr = lookupAppLocalizations(const Locale('tr'));

  // Wednesday 30 September 2026, 7:30 PM.
  final wed = DateTime(2026, 9, 30, 19, 30);

  setUpAll(() => initializeDateFormatting());

  group('locale resolution', () {
    test('follows the device language, matching on language only', () {
      expect(resolveAppLocale(null, const [Locale('fr', 'CA')]),
          const Locale('fr'));
      expect(resolveAppLocale(null, const [Locale('tr', 'TR')]),
          const Locale('tr'));
    });

    test('falls back to English for anything else', () {
      expect(resolveAppLocale(null, const [Locale('de', 'DE')]),
          const Locale('en'));
      expect(resolveAppLocale(null, const []), const Locale('en'));
    });

    test('takes the first supported language in the device list', () {
      expect(
        resolveAppLocale(null, const [Locale('ar'), Locale('tr')]),
        const Locale('tr'),
      );
    });

    test("the member's choice wins over the device", () {
      expect(
        resolveAppLocale(const Locale('tr'), const [Locale('fr', 'CA')]),
        const Locale('tr'),
      );
    });
  });

  group('upper', () {
    test('Turkish dotted i stays dotted', () {
      expect(upper('İkindi', 'tr'), 'İKİNDİ');
      expect(upper('Yatsı', 'tr'), 'YATSI');
      expect(upper('ismail', 'tr'), 'İSMAİL');
    });

    test('other languages are unchanged', () {
      expect(upper('Isha', 'en'), 'ISHA');
      expect(upper('ismail', 'fr'), 'ISMAIL');
    });
  });

  group('prayer names', () {
    test('timetable names', () {
      expect(prayerLabel(tr, 'Fajr'), 'İmsak');
      expect(prayerLabel(tr, 'Sunrise'), 'Güneş');
      expect(prayerLabel(tr, 'Maghrib'), 'Akşam');
      expect(prayerLabel(fr, 'Isha'), 'Icha');
      expect(prayerLabel(en, 'Dhuhr'), 'Dhuhr');
    });

    test('Turkish reminders name the prayer, not the time', () {
      expect(tr.prayerSalah('fajr'), 'Sabah namazı');
      expect(tr.reminderBody, 'Cemaate 5 dakika kaldı');
    });

    test('after a prayer', () {
      expect(tr.afterPrayer('maghrib'), 'Akşam namazından sonra');
      expect(fr.afterPrayerTitle('asr'), "Après la prière de l'Asr");
      expect(en.afterPrayerInline('maghrib'), 'after Maghrib');
    });
  });

  group('dates', () {
    test('title dates follow each language', () {
      expect(longDate(en, wed), 'Wednesday 30 September');
      expect(longDate(fr, wed), 'Mercredi 30 septembre');
      expect(longDate(tr, wed), '30 Eylül Çarşamba');
    });

    test('clock times are 12-hour in every language', () {
      expect(heroDateTime(en, wed), 'Wed 30 Sep · 7:30 PM');
      expect(heroDateTime(tr, wed), '30 Eylül Çarşamba · 7:30 PM');
      expect(heroDateTime(fr, wed), endsWith('7:30 PM'));
    });

    test('date tiles: no French full stops, Turkish capitals', () {
      expect(badgeWeekday(fr, wed), 'MER');
      expect(badgeMonth(fr, wed), 'SEPT');
      expect(badgeWeekday(tr, wed), 'ÇAR');
      expect(badgeMonth(tr, DateTime(2026, 10, 7)), 'EKİ');
    });

    test('hijri months', () {
      expect(hijriTitle(en, '11.2.1448'), '11 Safar 1448');
      expect(hijriTitle(tr, '11.2.1448'), '11 Safer 1448');
      expect(hijriTitle(fr, '1.9.1448'), '1 Ramadan 1448');
    });

    test('relative times are pluralised', () {
      final now = DateTime.now();
      expect(timeAgo(en, now.subtract(const Duration(hours: 1))),
          '1 hour ago');
      expect(timeAgo(fr, now.subtract(const Duration(days: 2))),
          'il y a 2 jours');
      expect(timeAgo(tr, now.subtract(const Duration(days: 14))),
          '2 hafta önce');
    });

    test('file sizes use the local decimal mark and units', () {
      expect(fileSize(en, 1800000), '1.8 MB');
      expect(fileSize(fr, 1800000), '1,8 Mo');
      expect(fileSize(tr, 240000), '240 KB');
    });
  });

  group('recurrence', () {
    test('every weekday', () {
      expect(recurrenceWhen(en, EventRecurrence.weekly, wed),
          'Every Wednesday');
      expect(recurrenceWhen(fr, EventRecurrence.weekly, wed),
          'Tous les mercredis');
      expect(recurrenceWhen(tr, EventRecurrence.weekly, wed), 'Her Çarşamba');
    });

    test('monthly on a day of the month', () {
      final first = DateTime(2026, 10, 1, 19, 30);
      expect(recurrenceRow(en, EventRecurrence.monthly, first).$1,
          'Every month on the 1st');
      expect(recurrenceRow(fr, EventRecurrence.monthly, first).$1,
          'Le 1er de chaque mois');
      expect(recurrenceRow(tr, EventRecurrence.monthly, first).$1,
          'Her ayın 1. günü');
      expect(
          recurrenceRow(en, EventRecurrence.monthly, DateTime(2026, 10, 12))
              .$1,
          'Every month on the 12th');
    });
  });

  test('every ARB file has the same keys and placeholders', () {
    Map<String, dynamic> read(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();
    final template = read('en');
    for (final lang in ['fr', 'tr']) {
      final arb = read(lang);
      expect(keys(arb), keys(template), reason: lang);
      for (final key in keys(template)) {
        final placeholders =
            (template['@$key']?['placeholders'] as Map?)?.keys ?? const [];
        for (final p in placeholders) {
          expect(arb[key], contains('{$p'), reason: '$lang.$key needs {$p}');
        }
      }
    }
  });
}
