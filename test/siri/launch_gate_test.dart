import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/launch_gate.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_refresh.dart';
import 'package:myt_flutter/core/push/push_platform.dart';
import 'package:myt_flutter/core/push/push_prompt.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:myt_flutter/features/push/push_prompt_sheet.dart';
import 'package:myt_flutter/main.dart';
import 'package:myt_flutter/shared/providers/auth_provider.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/shared/providers/donations_provider.dart';
import 'package:myt_flutter/shared/providers/events_news_provider.dart';
import 'package:myt_flutter/shared/providers/prayer_provider.dart';
import 'package:myt_flutter/shared/providers/push_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prayer/hero_identity_row_test.dart' show loadManrope;
import '../push/fakes.dart';

class _Platform implements PushPlatform {
  @override
  Future<void> openSystemSettings() async {}
  @override
  Future<PushPermission> status() async => PushPermission.notDetermined;
  @override
  Future<PushPermission> request() async => PushPermission.authorized;
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get tokenRefresh => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get opened => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get received => const Stream.empty();
  @override
  Future<Map<String, dynamic>?> initialOpen() async => null;
}

void main() {
  group('LaunchGate', () {
    test('a foreground launch runs at the first frame, once', () {
      var runs = 0;
      final gate = LaunchGate(startedInBackground: false, onFirstForeground: () => runs++);
      gate.firstFrame(isResumed: false);
      expect(runs, 1);
      expect(gate.resume(), isTrue, reason: 'a later resume does the usual work');
      expect(runs, 1);
    });

    test('a background launch waits for the first resume, then runs once', () {
      var runs = 0;
      final gate = LaunchGate(startedInBackground: true, onFirstForeground: () => runs++);
      gate.firstFrame(isResumed: false);
      expect(runs, 0);
      expect(gate.resume(), isFalse, reason: 'the launch work replaces this resume');
      expect(runs, 1);
      expect(gate.resume(), isTrue);
      expect(runs, 1);
    });

    test('coming forward before the listener existed still counts', () {
      var runs = 0;
      final gate = LaunchGate(startedInBackground: true, onFirstForeground: () => runs++);
      gate.firstFrame(isResumed: true);
      expect(runs, 1);
    });
  });

  group('the real app, launched by a Siri question', () {
    late int refreshes;
    late FakePushApi api;
    final original = prayerRefresh;
    final originalFlush = flushPendingAppleName;

    setUpAll(loadManrope);

    setUp(() {
      flushPendingAppleName = () async => false;
      initMosqueTime();
      SharedPreferences.setMockInitialValues({'app_launch_count': 4});
      refreshes = 0;
      api = FakePushApi();
      prayerRefresh = () async {
        refreshes++;
        return false;
      };
    });
    tearDown(() {
      prayerRefresh = original;
      flushPendingAppleName = originalFlush;
    });

    Future<void> launch(WidgetTester tester, {required bool background}) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // What main() does.
      final count = background
          ? await PushPromptStore.nextLaunch()
          : await PushPromptStore.countLaunch();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pushPlatformProvider.overrideWithValue(_Platform()),
            pushApiProvider.overrideWithValue(api),
            identityStoreProvider.overrideWithValue(MemoryIdentityStore()),
            initialPushPermissionProvider.overrideWithValue(PushPermission.notDetermined),
            initialPushLocalProvider.overrideWithValue(const PushLocal(saved: true)),
            launchCountProvider.overrideWithValue(count),
            appVersionProvider.overrideWithValue('1.4.0'),
            currentUserProvider.overrideWithValue(null),
            authStateProvider.overrideWith((ref) => const Stream.empty()),
            prayerProvider.overrideWith((ref) async => null),
            eventsProvider.overrideWith((ref) async => const []),
            newsProvider.overrideWith((ref) async => const <Announcement>[]),
            initialDonationFundsProvider.overrideWithValue(const []),
          ],
          child: MytApp(startedInBackground: background),
        ),
      );
    }

    // Past the pre-prompt's 1.2 s.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<int?> launches() async =>
        (await SharedPreferences.getInstance()).getInt('app_launch_count');

    testWidgets('does nothing until it comes forward', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await launch(tester, background: true);
      await settle(tester);

      expect(find.byType(PushPromptSheet), findsNothing, reason: 'no pre-prompt');
      expect(api.calls, isEmpty, reason: 'no register_device, so no push caps touched');
      expect(refreshes, 0, reason: 'reminders untouched');
      expect(await launches(), 4, reason: 'not counted as a launch');
    });

    testWidgets('then behaves as an ordinary launch, once', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await launch(tester, background: true);
      await settle(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);

      expect(refreshes, 1);
      expect(api.calls, contains('register'));
      expect(await launches(), 5);
      expect(find.byType(PushPromptSheet), findsOneWidget);
    });

    testWidgets('a normal launch is unchanged', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await launch(tester, background: false);
      await settle(tester);

      expect(refreshes, 1);
      expect(api.calls, contains('register'));
      expect(await launches(), 5);
      expect(find.byType(PushPromptSheet), findsOneWidget);
    });

    testWidgets('going to the background before the prompt fires skips it', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await launch(tester, background: false);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await settle(tester);
      expect(find.byType(PushPromptSheet), findsNothing);
    });
  });
}
