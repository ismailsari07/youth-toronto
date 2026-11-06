import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `INPreferences` throws an Objective-C exception, which Swift can't catch,
/// in a process without `com.apple.developer.siri`. TestFlight 1.4.0 build 26
/// crashed on every shortcut because of it.
void main() {
  List<File> swiftFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.swift'))
      .toList();

  bool usesINPreferences(File f) =>
      f.readAsStringSync().split('\n').any((line) {
        final code = line.split('//').first;
        return code.contains('INPreferences');
      });

  bool hasSiriEntitlement(String path) => RegExp(
        r'<key>com\.apple\.developer\.siri</key>\s*<true/>',
      ).hasMatch(File(path).readAsStringSync());

  test('the app carries the Siri entitlement while it reads INPreferences', () {
    final users = swiftFiles('ios/Runner').where(usesINPreferences).toList();
    expect(users, isNotEmpty, reason: 'drop this test with the call');
    expect(
      hasSiriEntitlement('ios/Runner/Runner.entitlements'),
      isTrue,
      reason: '${users.map((f) => f.path).join(', ')} call INPreferences',
    );
  });

  test('the widget never reads INPreferences (it has no Siri entitlement)', () {
    expect(hasSiriEntitlement('ios/PrayerWidget/PrayerWidget.entitlements'), isFalse);
    expect(swiftFiles('ios/PrayerWidget').where(usesINPreferences), isEmpty);
  });

  test('Debug, Profile and Release all sign with Runner.entitlements', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'.allMatches(project).length,
      3,
    );
  });
}
