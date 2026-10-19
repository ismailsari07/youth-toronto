import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/prayer_refresh.dart';
import 'package:myt_flutter/core/push/push_api.dart';
import 'package:myt_flutter/core/push/push_prompt.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:myt_flutter/features/profile/screens/profile_root_screen.dart';
import 'package:myt_flutter/features/profile/screens/settings_screen.dart';
import 'package:myt_flutter/features/profile/widgets/about_sheet.dart';
import 'package:myt_flutter/features/push/push_widgets.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/auth_provider.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/shared/providers/push_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const eventId = '0b9f3c8e-2d1a-4c5b-9e7f-112233445566';

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  PushPermission permission = PushPermission.authorized,
  PushLocal local = const PushLocal(saved: true),
  FakePushApi? api,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialPushPermissionProvider.overrideWithValue(permission),
        initialPushLocalProvider.overrideWithValue(local),
        appVersionProvider.overrideWithValue('1.0.8'),
        currentUserProvider.overrideWithValue(null),
        pushApiProvider.overrideWithValue(api ?? FakePushApi()),
        identityStoreProvider.overrideWithValue(MemoryIdentityStore()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Settings', () {
    testWidgets('both switches, on by default; no hint when allowed', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen());
      expect(find.text('Event notifications'), findsOneWidget);
      expect(find.text('Announcements and important news'), findsOneWidget);
      expect(find.text('Notifications are off in iPhone Settings'), findsNothing);
      final switches = tester.widgetList<AppSwitch>(find.byType(AppSwitch));
      expect(switches.map((s) => s.value), [true, true]);
      expect(find.text('Version 1.0.8'), findsOneWidget);
    });

    testWidgets('denied: hint and Open Settings above usable switches', (
      tester,
    ) async {
      await pump(
        tester,
        const SettingsScreen(),
        permission: PushPermission.denied,
      );
      expect(find.text('Notifications are off in iPhone Settings'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      final hint = tester.getTopLeft(find.text('Open Settings')).dy;
      final events = tester.getTopLeft(find.text('Event notifications')).dy;
      expect(hint, lessThan(events));
      expect(
        tester.widgetList<AppSwitch>(find.byType(AppSwitch)).every(
              (s) => s.onChanged != null,
            ),
        isTrue,
      );
    });

    testWidgets('where push does not run, no push switches', (tester) async {
      await pump(
        tester,
        const SettingsScreen(),
        permission: PushPermission.unsupported,
      );
      expect(find.text('Event notifications'), findsNothing);
    });
  });

  group('event toggle', () {
    testWidgets('on by default', (tester) async {
      await pump(tester, const EventNotifyCard(eventId: eventId));
      expect(find.text('Notify me about this event'), findsOneWidget);
      expect(find.text('A reminder before it starts'), findsOneWidget);
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
    });

    testWidgets('muted event shows off', (tester) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId),
        local: const PushLocal(saved: true, muted: {eventId}),
      );
      expect(find.text('Off for this event'), findsOneWidget);
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    });

    testWidgets('registered: on and locked, even if muted before', (tester) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId, locked: true),
        local: const PushLocal(saved: true, muted: {eventId}),
      );
      expect(find.text("On because you're registered"), findsOneWidget);
      final toggle = tester.widget<AppSwitch>(find.byType(AppSwitch));
      expect((toggle.value, toggle.onChanged), (true, null));
    });

    testWidgets('locked still says when push is off (D5)', (tester) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId, locked: true),
        permission: PushPermission.denied,
      );
      expect(find.text("On because you're registered"), findsNothing);
    });

    testWidgets("muting answers 'registered': snaps back on, no error", (tester) async {
      final api = FakePushApi()..eventErrors.add(PushError.registered);
      await pump(tester, const EventNotifyCard(eventId: eventId), api: api);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('disabled while Event notifications is off', (tester) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId),
        local: const PushLocal(saved: true, events: false),
      );
      expect(find.text('Event notifications are off'), findsOneWidget);
      expect(
        tester.widget<AppSwitch>(find.byType(AppSwitch)).onChanged,
        isNull,
      );
    });

    testWidgets('denied: the hint and Open Settings instead of a switch', (
      tester,
    ) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId),
        permission: PushPermission.denied,
      );
      expect(find.text('Notifications are off in iPhone Settings'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byType(AppSwitch), findsNothing);
    });

    testWidgets('hidden where push does not run', (tester) async {
      await pump(
        tester,
        const EventNotifyCard(eventId: eventId),
        permission: PushPermission.unsupported,
      );
      expect(find.text('Notify me about this event'), findsNothing);
    });

    testWidgets('a refused save puts the switch back and says so', (
      tester,
    ) async {
      final api = FakePushApi()..eventErrors.add(PushError.limited);
      await pump(tester, const EventNotifyCard(eventId: eventId), api: api);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
      expect(
        find.text("Couldn't save. Try again in a little while."),
        findsOneWidget,
      );
    });

    testWidgets('a saved change stays', (tester) async {
      final api = FakePushApi();
      await pump(tester, const EventNotifyCard(eventId: eventId), api: api);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
      expect(api.mutes, [(eventId, false)]);
    });
  });

  group('About sheet', () {
    testWidgets('version and device code', (tester) async {
      await pump(
        tester,
        const AboutSheet(),
        local: const PushLocal(saved: true, deviceCode: 'K7QM2X9P'),
      );
      expect(find.text('1.0.8'), findsOneWidget);
      expect(find.text('K7QM2X9P'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('a dash before the first registration', (tester) async {
      await pump(tester, const AboutSheet());
      // The device code, and the background refresh that never happened.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('last background refresh: a dash, then its date and time', (
      tester,
    ) async {
      await pump(
        tester,
        const AboutSheet(),
        local: const PushLocal(saved: true, deviceCode: 'K7QM2X9P'),
      );
      expect(find.text('Last background refresh'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      // Stored in UTC, shown in the phone's time.
      final at = DateTime(2026, 10, 19, 14, 32);
      await tester.runAsync(() => BackgroundRefreshLog.record(at));
      await pump(tester, const SizedBox());
      await pump(
        tester,
        const AboutSheet(),
        local: const PushLocal(saved: true, deviceCode: 'K7QM2X9P'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mon 19 Oct · 2:32 PM'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('no line where push is unsupported', (tester) async {
      await pump(
        tester,
        const AboutSheet(),
        permission: PushPermission.unsupported,
      );
      expect(find.text('Last background refresh'), findsNothing);
    });

    testWidgets('opens from the About row on Profile', (tester) async {
      await pump(
        tester,
        const ProfileRootScreen(),
        local: const PushLocal(saved: true, deviceCode: 'K7QM2X9P'),
      );
      // Taller than the default 800×600: Profile also lists Prayer reminders.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      final row = find.text('About this app');
      await tester.scrollUntilVisible(row, 200);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(AboutSheet), findsOneWidget);
      expect(find.text('K7QM2X9P'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });
  });
}
