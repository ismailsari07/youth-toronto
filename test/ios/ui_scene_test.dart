import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flutter's UIScene migration, as far as it can be checked without Xcode. The
/// built app is checked by tool/check_scene_manifest.py in siri-check.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  test('Info.plist has the official manifest, one scene, the stock delegate', () {
    final compact = plist.replaceAll(RegExp(r'\s+'), '');
    expect(compact, contains('<key>UIApplicationSupportsMultipleScenes</key><false/>'));
    expect(compact, contains('<key>UIWindowSceneSessionRoleApplication</key><array><dict>'));
    for (final (key, value) in const [
      ('UISceneClassName', 'UIWindowScene'),
      ('UISceneDelegateClassName', 'FlutterSceneDelegate'),
      ('UISceneConfigurationName', 'flutter'),
      ('UISceneStoryboardFile', 'Main'),
    ]) {
      expect(compact, contains('<key>$key</key><string>$value</string>'));
    }
  });

  group('AppDelegate', () {
    String method(String signature) {
      final start = delegate.indexOf(signature);
      expect(start, isNonNegative, reason: signature);
      final end = delegate.indexOf('\n  }\n', start);
      return delegate.substring(start, end);
    }

    test('registers everything once the engine exists, not at launch', () {
      expect(delegate, contains('FlutterAppDelegate, FlutterImplicitEngineDelegate'));
      final engine = method('func didInitializeImplicitFlutterEngine');
      for (final call in const [
        'GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)',
        'registerPrayerWidgetBridge(messenger)',
        'registerNotificationSoundBridge(messenger)',
        'registerSiriBridge(messenger)',
      ]) {
        expect(engine, contains(call));
      }
      final launch = method('override func application(');
      expect(launch, isNot(contains('register')));
      expect(delegate, isNot(contains('register(with: self)')));
      expect(delegate, isNot(contains('self.registrar(')));
    });

    test('the notification delegate is still set during launch', () {
      expect(
        method('override func application('),
        contains('UNUserNotificationCenter.current().delegate = self'),
      );
    });

    test('a second engine replaces the Siri observer instead of adding one', () {
      expect(method('private func registerSiriBridge'), contains('removeObserver(old)'));
    });

    test('siri-check can find its line, and only in Debug', () {
      final line = delegate.indexOf('PapeScene: Flutter engine ready');
      expect(delegate.lastIndexOf('#if DEBUG', line), isNonNegative);
      expect(delegate.indexOf('#endif', line), greaterThan(line));
      expect(
        File('tool/check_simulator_launch.sh').readAsStringSync(),
        contains('PapeScene: Flutter engine ready'),
      );
    });

    // Flutter's template doesn't define DEBUG for Runner, so the line above was
    // compiled out and siri-check failed with a working app (1.4.0, 0103d81).
    test('the Runner target defines DEBUG in Debug, and only there', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      Map<String, String> runnerConfigs() {
        final list = RegExp(
          r'Build configuration list for PBXNativeTarget "Runner" \*/ = \{.*?buildConfigurations = \((.*?)\);',
          dotAll: true,
        ).firstMatch(project)![1]!;
        return {
          for (final m in RegExp(r'(\w{24}) /\* (\w+) \*/').allMatches(list))
            m[2]!: RegExp('${m[1]} /\\* ${m[2]} \\*/ = \\{(.*?)name = ${m[2]};', dotAll: true)
                .firstMatch(project)![1]!,
        };
      }

      final configs = runnerConfigs();
      expect(configs.keys, containsAll(['Debug', 'Release', 'Profile']));
      expect(configs['Debug'], contains('SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;'));
      expect(configs['Release'], isNot(contains('SWIFT_ACTIVE_COMPILATION_CONDITIONS')));
      expect(configs['Profile'], isNot(contains('SWIFT_ACTIVE_COMPILATION_CONDITIONS')));
    });
  });

  test('no native code uses what UIScene takes away', () {
    final bad = RegExp(
      r'launchOptions\??\[|\.keyWindow|\.shared\.windows|delegate\??\.window|UIScreen\.main|'
      r'func applicationDidBecomeActive|func applicationWillResignActive|'
      r'func applicationDidEnterBackground|func applicationWillEnterForeground',
    );
    final files = [
      ...Directory('ios/Runner').listSync(recursive: true).whereType<File>(),
    ].where((f) => f.path.endsWith('.swift'));
    expect(files, isNotEmpty);
    final found = [
      for (final f in files)
        if (bad.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(found, isEmpty);
  });

  test('siri-check runs both checks on the build', () {
    final yaml = File('codemagic.yaml').readAsStringSync();
    expect(yaml, contains('python3 tool/check_scene_manifest.py build/ios/iphonesimulator/Runner.app'));
    expect(yaml, contains('bash tool/check_simulator_launch.sh build/ios/iphonesimulator/Runner.app'));
  });
}
