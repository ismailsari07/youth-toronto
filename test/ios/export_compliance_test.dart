import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// docs/export-compliance.md: the app bundles libsodium for the encrypted
/// marriage application, so it must not claim to be exempt.
void main() {
  test('Info.plist declares non-exempt encryption while libsodium is bundled', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync().replaceAll(RegExp(r'\s+'), '');
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('sodium_libs:'));
    expect(plist, contains('<key>ITSAppUsesNonExemptEncryption</key><true/>'));
  });
}
