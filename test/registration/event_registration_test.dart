import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:myt_flutter/features/community/screens/event_detail_screen.dart';
import 'package:myt_flutter/features/registration/event_registration_section.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_controls.dart';
import 'package:myt_flutter/ui/components/event_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'harness.dart';

/// §10.5: what the event page shows for each answer of the state call.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeRegistrationApi> page(
    WidgetTester tester,
    List<Object> states, {
    String recurrence = 'none',
    ThemeData? theme,
    PushLocal pushLocal = const PushLocal(saved: true),
  }) async {
    tester.view.physicalSize = const Size(430 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = FakeRegistrationApi(states);
    await pumpRegistration(
      tester,
      api,
      theme: theme,
      pushLocal: pushLocal,
      home: (_) => EventDetailScreen(upcoming: upcomingEvent(recurrence: recurrence)),
    );
    return api;
  }

  Finder bar() => find.byType(RegistrationBar);
  Finder inBar(String text) => find.descendant(of: bar(), matching: find.text(text));

  testWidgets('open, member: status, places, deadline, views, Register', (tester) async {
    final api = await page(tester, [
      stateJson(me: member(), placesLeft: 3, deadline: '2026-11-06T23:59:00+00:00'),
    ]);
    expect(find.text('Registration open'), findsOneWidget);
    expect(find.text('Last 3 places'), findsOneWidget);
    expect(find.textContaining('Register by 6 November'), findsOneWidget);
    expect(find.text('30 people viewed'), findsOneWidget);
    expect(inBar('Register'), findsOneWidget);
    expect(find.text('Drop in — no registration needed'), findsNothing);
    // State and view in parallel, the view with this device's credentials.
    expect(api.stateCalls, 1);
    expect(api.viewCalls.single, (eventId, device));
  });

  testWidgets('views below the threshold: no line', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = FakeRegistrationApi([stateJson(me: member())])..views = null;
    await pumpRegistration(tester, api, home: (_) => EventDetailScreen(upcoming: upcomingEvent()));
    expect(find.textContaining('people viewed'), findsNothing);
  });

  testWidgets('signed out: sign in, then back to the event', (tester) async {
    await page(tester, [stateJson()]);
    expect(inBar('Sign in to register'), findsOneWidget);
    expect(inBar('You need to sign in to register.'), findsOneWidget);
    await tester.tap(inBar('Sign in to register'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN SCREEN'), findsOneWidget);
  });

  testWidgets('member without a profile: disabled, with the reason (D2)', (tester) async {
    await page(tester, [stateJson(me: {'has_profile': false, 'registration': null})]);
    expect(find.descendant(of: bar(), matching: find.byType(DisabledButton)), findsOneWidget);
    expect(inBar("This account can't register for events."), findsOneWidget);
  });

  for (final (status, card, button, extra) in [
    ('full', 'Registration is full', 'Registration is full', null),
    ('deadline_passed', 'Registration has ended', 'Registration has ended', 'Registration closed on'),
    ('closed', 'Registration is closed', 'Registration is closed', null),
    ('waitlist', 'Registration is closed', 'Registration is closed', null),
  ]) {
    testWidgets('$status: card and a disabled button', (tester) async {
      await page(tester, [
        stateJson(status: status, me: member(), deadline: '2026-11-06T23:59:00+00:00'),
      ]);
      expect(find.text(card), findsWidgets);
      expect(
        find.descendant(of: find.byType(DisabledButton), matching: find.text(button)),
        findsOneWidget,
      );
      expect(find.text('Last 3 places'), findsNothing);
      if (extra != null) expect(find.textContaining(extra), findsOneWidget);
    });
  }

  testWidgets('registered: summary, no bar, notification row locked on', (tester) async {
    await page(tester, [
      stateJson(
        status: 'registered',
        me: member(registration: {
          'created_at': '2026-10-18T18:05:00+00:00',
          'full_name': 'Zeynep Aksoy',
          'phone': '+14165550123',
          'answers': {
            'q_SHRT2222': 'Danforth CI',
            'q_SNGL2222': 'o_AAAAA3',
            'q_MLTP2222': ['o_BBBBB2', 'o_BBBBB3'],
            'q_YSN22222': false,
            'q_DATE2222': '2010-05-04',
          },
        }),
      ),
    ]);
    expect(find.text("You're registered"), findsOneWidget);
    expect(find.text('Registered on 18 October 2026'), findsOneWidget);
    expect(find.text('What you sent'), findsOneWidget);
    for (final text in ['Zeynep Aksoy', 'zeynep@example.com', '+14165550123', 'Danforth CI', 'M',
      'Calligraphy, Sports', 'No']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('4 May 2010'), findsOneWidget);
    expect(find.byType(DisabledButton), findsNothing);
    expect(find.text('Register'), findsNothing);
    expect(find.text("On because you're registered"), findsOneWidget);
    final toggle = tester.widget<AppSwitch>(find.byType(AppSwitch));
    expect((toggle.value, toggle.onChanged), (true, null));
  });

  testWidgets('registered while the events switch is off: the Settings row stays (D5)', (
    tester,
  ) async {
    await page(
      tester,
      [stateJson(status: 'registered', me: member(registration: {
        'created_at': '2026-10-18T18:05:00+00:00', 'full_name': 'Z', 'answers': {},
      }))],
      pushLocal: const PushLocal(saved: true, events: false),
    );
    expect(find.text("On because you're registered"), findsNothing);
  });

  testWidgets('kill switch: nothing, but a member keeps their registration (D4)', (tester) async {
    await page(tester, [stateJson(available: false, me: member())]);
    expect(find.text('Registration open'), findsNothing);
    expect(bar(), findsOneWidget);
    expect(find.descendant(of: bar(), matching: find.byType(GestureDetector)), findsNothing);
  });

  testWidgets('kill switch, registered: the summary stays', (tester) async {
    await page(tester, [
      stateJson(status: 'registered', available: false, me: member(registration: {
        'created_at': '2026-10-18T18:05:00+00:00', 'full_name': 'Z', 'answers': {},
      })),
    ]);
    expect(find.text("You're registered"), findsOneWidget);
  });

  testWidgets('P0002: no longer takes registrations, no button', (tester) async {
    await page(tester, [const PostgrestException(message: 'event_not_found', code: 'P0002')]);
    expect(find.text('This event no longer takes registrations.'), findsOneWidget);
    expect(find.text('Register'), findsNothing);
  });

  testWidgets("couldn't load: Try again refetches", (tester) async {
    final api = await page(tester, [Exception('offline'), stateJson(me: member())]);
    expect(find.text("Couldn't load registration details."), findsOneWidget);
    await tester.tap(inBar('Try again'));
    await tester.pumpAndSettle();
    expect(api.stateCalls, 2);
    expect(inBar('Register'), findsOneWidget);
  });

  testWidgets('recurring: the registration covers the whole programme', (tester) async {
    await page(tester, [stateJson(me: member())], recurrence: 'weekly');
    expect(find.text('This registration covers the whole programme.'), findsOneWidget);
  });

  testWidgets('dark mode renders', (tester) async {
    await page(tester, [stateJson(me: member(), placesLeft: 1)], theme: appDarkTheme);
    expect(find.text('Last place'), findsOneWidget);
  });

  group('event card', () {
    Future<void> card(WidgetTester tester, {required bool withForm}) => pumpRegistration(
          tester,
          FakeRegistrationApi([stateJson()]),
          home: (_) => Scaffold(
            body: EventCard(upcoming: upcomingEvent(withForm: withForm)),
          ),
        );

    testWidgets('an event with a form has the badge and no button (D7)', (tester) async {
      await card(tester, withForm: true);
      expect(find.text('Registration'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets('an event without a form has no badge', (tester) async {
      await card(tester, withForm: false);
      expect(find.text('Registration'), findsNothing);
    });
  });
}
