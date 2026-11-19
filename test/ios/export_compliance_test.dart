import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// docs/export-compliance.md: the app bundles libsodium for the encrypted
/// marriage application. It must not claim to be exempt (`false`), and it has
/// no approved compliance documentation, so it must not declare `true` either:
/// App Store Connect refuses `true` without a matching
/// ITSEncryptionExportComplianceCode (ITMS-90592, 1.5.0 build 30). With neither
/// key, App Store Connect asks the export questions for each build.
void main() {
  test('Info.plist leaves the export-compliance keys out while libsodium is bundled', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('sodium_libs:'));
    expect(plist, isNot(contains('ITSAppUsesNonExemptEncryption')));
    expect(plist, isNot(contains('ITSEncryptionExportComplianceCode')));
  });

  test('no other plist in the app or the widget sets an export-compliance key', () {
    for (final path in ['ios/PrayerWidget/Info.plist', 'ios/Flutter/AppFrameworkInfo.plist']) {
      final text = File(path).readAsStringSync();
      expect(text, isNot(contains('ITSAppUsesNonExemptEncryption')), reason: path);
      expect(text, isNot(contains('ITSEncryptionExportComplianceCode')), reason: path);
    }
  });
}
