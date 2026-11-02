import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _strings(String path) {
  final out = <String, String>{};
  final line = RegExp(r'^"((?:[^"\\]|\\.)*)" = "((?:[^"\\]|\\.)*)";$');
  for (final raw in File(path).readAsLinesSync()) {
    final m = line.firstMatch(raw.trim());
    if (m != null) out[m[1]!] = m[2]!;
  }
  return out;
}

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

/// `fajr{İmsak}` out of the `prayer` select message.
String _prayerName(Map<String, dynamic> arb, String key) =>
    RegExp('$key\\{([^}]*)\\}').firstMatch(arb['prayer'] as String)![1]!;

void main() {
  final swiftText = File('ios/Runner/Siri/SiriText.swift').readAsStringSync();
  final shortcuts = File('ios/Runner/Siri/PapeShortcuts.swift').readAsStringSync();

  // `.tr: [.fajr: "İmsak", ...]` in SiriTerms.names.
  String swiftName(String lang, String key) {
    final row = RegExp('\\.$lang: \\[\\.fajr.*').firstMatch(swiftText)![0]!;
    return RegExp('\\.$key: "([^"]*)"').firstMatch(row)![1]!;
  }

  String swiftTerm(String table, String lang) {
    final body = RegExp('static let $table: \\[SiriLanguage: String\\] = \\[([^\\]]*)\\]')
        .firstMatch(swiftText)![1]!;
    return RegExp('\\.$lang: "([^"]*)"').firstMatch(body)![1]!;
  }

  for (final lang in const ['en', 'tr', 'fr']) {
    group('Siri says what the app says ($lang)', () {
      final arb = _arb(lang);

      test('prayer names', () {
        for (final key in const ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
          expect(swiftName(lang, key), _prayerName(arb, key), reason: key);
        }
      });

      test('athan, iqamah, Jumu\'ah, Eid', () {
        expect('${swiftTerm('athan', lang)} {time}', arb['athanAt']);
        expect('${swiftTerm('iqamah', lang)} {time}', arb['iqamahAt']);
        expect(swiftTerm('jumuah', lang), arb['jumuah']);
        expect(swiftTerm('eidFitr', lang), arb['eidFitr']);
        expect(swiftTerm('eidAdha', lang), arb['eidAdha']);
      });
    });
  }

  group('App Shortcuts', () {
    final phrases = RegExp(r'^\s*"(.*\\\(.*)",$', multiLine: true)
        .allMatches(shortcuts)
        .map((m) => m[1]!
            .replaceAll(r'\(.applicationName)', r'${applicationName}')
            .replaceAll(r'\(\.$prayer)', r'${prayer}'))
        .toList();

    test("exactly Apple's limit of ten", () {
      expect(RegExp(r'AppShortcut\(').allMatches(shortcuts).length, 10);
    });

    test('three phrases each, all containing the app name once', () {
      expect(phrases.length, 30);
      expect(phrases.toSet().length, 30, reason: 'no duplicates');
    });

    for (final lang in const ['en', 'tr', 'fr']) {
      test('$lang translates exactly those phrases', () {
        final file = _strings('ios/Runner/$lang.lproj/AppShortcuts.strings');
        expect(file.keys.toSet(), phrases.toSet());
        expect(file.values.toSet().length, 30, reason: 'no duplicates');
        for (final MapEntry(:key, :value) in file.entries) {
          expect(r'${applicationName}'.allMatches(value).length, 1, reason: value);
          expect(
            r'${prayer}'.allMatches(value).length,
            r'${prayer}'.allMatches(key).length,
            reason: value,
          );
        }
      });

      test('$lang names the app three other ways', () {
        final file = _strings('ios/Runner/$lang.lproj/InfoPlist.strings');
        for (final n in const [1, 2, 3]) {
          expect(file['APP_NAME_SYNONYM_$n'], isNotEmpty);
        }
      });

      test('$lang has every title the intents declare', () {
        final file = _strings('ios/Runner/$lang.lproj/Localizable.strings');
        final intents = File('ios/Runner/Siri/SiriIntents.swift').readAsStringSync();
        final titles = RegExp(r'(?:LocalizedStringResource = |IntentDescription\(|title: |IntentDialog\()"([^"]+)"')
            .allMatches(intents)
            .map((m) => m[1]!);
        for (final title in titles) {
          expect(file[title], isNotEmpty, reason: title);
        }
        final short = RegExp(r'shortTitle: "([^"]+)"').allMatches(shortcuts).map((m) => m[1]!);
        for (final title in short) {
          expect(file[title], isNotEmpty, reason: title);
        }
      });
    }

    test('Pape Camii\'nde is accepted in Turkish, as the owner asked', () {
      final file = _strings('ios/Runner/tr.lproj/InfoPlist.strings');
      expect(file.values, containsAll(['Pape Camii', "Pape Camii'nde", 'Mosquée Pape']));
    });
  });

  test('the Xcode project includes every Siri file', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    for (final file in Directory('ios/Runner/Siri').listSync()) {
      final name = file.path.split('/').last;
      expect(project, contains('$name in Sources'), reason: name);
    }
    expect(project, contains('SiriLogicTests.swift in Sources'));
    expect(project, contains('AppShortcuts.strings in Resources'));
    expect('-weak_framework'.allMatches(project).length, 3, reason: 'iOS 15 has no AppIntents');
  });
}
