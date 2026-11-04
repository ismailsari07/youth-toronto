import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// App Store Connect refuses a build whose App Intent text names Apple's
// products (ITMS-90626, build 23 of 1.4.0: "cannot contain 'siri'", "'apple'").
// It only shows at upload, after a full release build, so it is checked here.
//
// Matched anywhere in a word, not as whole words, because Apple doesn't say how
// its check matches.
const _forbidden = [
  'siri',
  'apple',
  'iphone',
  'ipad',
  'ipod',
  'ios',
  'ipados',
  'macos',
  'watchos',
  'tvos',
  'visionos',
  'homepod',
  'carplay',
  'facetime',
  'icloud',
  'safari',
  'app store',
];

// Strings in the scanned code that no one reads: an internal notification name
// and the address the directions open.
const _notText = {
  'ca.papemosque.app.siriAction',
  'https://maps.apple.com/',
};

const _swiftFiles = [
  'ios/Runner/Siri/SiriIntents.swift', // titles, descriptions, parameters, dialogs
  'ios/Runner/Siri/PapeShortcuts.swift', // phrases, short titles
  'ios/Runner/Siri/SiriText.swift', // what's spoken, what the snippets show
  'ios/Runner/Siri/SiriCardView.swift', // the snippet's own labels
];

const _stringsFiles = ['AppShortcuts', 'Localizable', 'InfoPlist'];

/// The forbidden words in [text], case-insensitive. Turkish's capital İ would
/// otherwise lowercase to two characters and slip past "siri".
List<String> _found(String text) {
  final lower = text.replaceAll('İ', 'i').toLowerCase();
  return _forbidden.where(lower.contains).toList();
}

/// Every string literal in Swift [source], without comments and without the
/// code inside `\(...)`: `SiriTerms.names` there is a type, not text. A string
/// inside an interpolation counts as its own literal.
List<String> _swiftLiterals(String source) {
  final out = <String>[];

  late int Function(int) readString;

  int readInterpolation(int start) {
    var i = start;
    var depth = 1;
    while (i < source.length && depth > 0) {
      final c = source[i];
      if (c == '"') {
        i = readString(i + 1);
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') depth--;
      i++;
    }
    return i;
  }

  readString = (int start) {
    final text = StringBuffer();
    var i = start;
    while (i < source.length) {
      final c = source[i];
      if (c == '"') {
        out.add(text.toString());
        return i + 1;
      }
      if (c == r'\' && i + 1 < source.length) {
        if (source[i + 1] == '(') {
          i = readInterpolation(i + 2);
        } else {
          text.write(source[i + 1]);
          i += 2;
        }
        continue;
      }
      text.write(c);
      i++;
    }
    fail('unterminated string in Swift source');
  };

  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      if (end < 0) break;
      i = end;
    } else if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i);
      if (end < 0) break;
      i = end + 2;
    } else if (source[i] == '"') {
      i = readString(i + 1);
    } else {
      i++;
    }
  }
  return out;
}

/// A .strings file with its comments removed, keys and values both kept: read
/// whole so a line a parser wouldn't recognize can't escape the check.
String _withoutComments(String strings) =>
    strings.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

void main() {
  group('the scan itself', () {
    test('finds what App Store Connect rejected, in any case', () {
      expect(_found('Calls the mosque, after Siri confirms.'), ['siri']);
      expect(_found('Opens Apple Maps with directions to the mosque.'), ['apple']);
      expect(_found('SİRİ'), ['siri']);
      expect(_found('on your IPHONE'), ['iphone']);
      expect(_found('Opens directions to the mosque in Maps.'), isEmpty);
    });

    test('reads the text of a literal, not comments or interpolated code', () {
      const swift = r'''
// Siri in a comment
/* Apple in a comment */
let a = "Next \(SiriTerms.name[key] ?? "iPhone") prayer"
let b = SiriEngine.current()
''';
      expect(_swiftLiterals(swift), ['iPhone', 'Next  prayer']);
    });
  });

  for (final path in _swiftFiles) {
    test('$path has no forbidden word in any string', () {
      final literals = _swiftLiterals(File(path).readAsStringSync());
      expect(literals, isNotEmpty, reason: 'nothing read: the scan would pass on anything');

      final bad = {
        for (final text in literals)
          if (!_notText.contains(text) && _found(text).isNotEmpty) text: _found(text),
      };
      expect(bad, isEmpty);
    });
  }

  for (final lang in const ['en', 'tr', 'fr']) {
    for (final name in _stringsFiles) {
      test('$lang.lproj/$name.strings has no forbidden word', () {
        final text = _withoutComments(File('ios/Runner/$lang.lproj/$name.strings').readAsStringSync());
        expect(text.trim(), isNotEmpty);
        final bad = [
          for (final line in text.split('\n'))
            if (_found(line).isNotEmpty) line,
        ];
        expect(bad, isEmpty);
      });
    }
  }

  test('the exceptions are still in use, so none outlives its reason', () {
    final all = _swiftFiles.expand((path) => _swiftLiterals(File(path).readAsStringSync())).toSet();
    expect(all, containsAll(_notText));
  });
}
