import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_widget_sync.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:timezone/timezone.dart' as tz;

/// The shortcuts answer in Siri's language only when iOS authorizes the app
/// to know it; otherwise in the language the app shows, which Swift reads
/// from the widget's document (`locale`). TestFlight 1.4.0: a Turkish Siri on
/// an English iPhone, with the app in Turkish, answered in English.
/// The resolution itself is tested in Swift (SiriLogicTests).
void main() {
  setUpAll(initMosqueTime);

  final swiftData = File('ios/Runner/Siri/SiriData.swift').readAsStringSync();
  final swiftText = File('ios/Runner/Siri/SiriText.swift').readAsStringSync();
  final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  String constant(String source, String name) =>
      RegExp('static let $name = "([^"]+)"').firstMatch(source)![1]!;

  test('Swift reads the key the widget data is written under', () {
    expect(constant(swiftData, 'widgetData'), constant(delegate, 'widgetDataKey'));
  });

  for (final lang in const ['en', 'tr', 'fr']) {
    test('the widget data names the app language ($lang)', () {
      final now = tz.TZDateTime(mosqueTz, 2026, 11, 6, 10);
      final data = buildPrayerWidgetData(const [], lookupAppLocalizations(Locale(lang)), now);
      expect(data['locale'], lang);
    });
  }

  test("Siri's code counts only when authorized, then the app, then the device", () {
    expect(swiftText, contains('INPreferences.siriAuthorizationStatus()'));
    expect(
      swiftText,
      contains('resolve(siri: siri, siriAuthorized: authorized, app: app, device: device)'),
    );
    expect(
      swiftText,
      contains('for code in [siriAuthorized ? siri : nil, app, device]'),
    );
  });

  test('no Siri permission prompt: the app never asks for authorization', () {
    final files = Directory('ios/Runner')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.swift'));
    for (final f in files) {
      expect(f.readAsStringSync(), isNot(contains('requestSiriAuthorization')), reason: f.path);
    }
    expect(File('ios/Runner/Info.plist').readAsStringSync(), isNot(contains('NSSiriUsageDescription')));
  });
}
