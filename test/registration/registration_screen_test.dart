import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myt_flutter/features/registration/question_fields.dart';
import 'package:myt_flutter/features/registration/registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'harness.dart';

/// The form screen: Bilgilerin, sending, and every way sending can fail.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<bool?> results;

  Future<FakeRegistrationApi> open(
    WidgetTester tester,
    List<Object> states, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(430 * 3, 3200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    results = [];
    final api = FakeRegistrationApi(states);
    await pumpRegistration(
      tester,
      api,
      locale: locale,
      home: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async => results.add(
              await context.push<bool>('/community/event/register', extra: upcomingEvent()),
            ),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    return api;
  }

  Finder question(String label) => find.ancestor(
        of: find.text(label, findRichText: true),
        matching: find.byType(QuestionField),
      );
  Finder textIn(Finder f) => find.descendant(of: f, matching: find.byType(TextField));

  Future<void> fillRequired(WidgetTester tester) async {
    await tester.enterText(textIn(question('School *')), '  Danforth CI ');
    await tester.tap(find.descendant(of: question('Shuttle? *'), matching: find.text('No')));
    await tester.pump();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('registration-submit')));
    await tester.pumpAndSettle();
  }

  group('Bilgilerin', () {
    testWidgets('read-only name and email; phone input when missing; no-cancel note', (
      tester,
    ) async {
      await open(tester, [stateJson(me: member(), requirePhone: true)]);
      expect(find.text('Zeynep Aksoy'), findsOneWidget);
      expect(find.text('zeynep@example.com'), findsOneWidget);
      expect(find.text('Phone *', findRichText: true), findsOneWidget);
      expect(find.text('Saved to your profile'), findsOneWidget);
      expect(find.text("A registration can't be cancelled in the app."), findsOneWidget);
      // Every question, required ones starred.
      expect(find.byType(QuestionField), findsNWidgets(8));
      expect(find.text('School *', findRichText: true), findsOneWidget);
      expect(find.text('Age', findRichText: true), findsOneWidget);
    });

    testWidgets('name missing: an input; empty email hidden', (tester) async {
      await open(tester, [stateJson(me: member(nameMissing: true, email: ''))]);
      expect(find.text('Full name *', findRichText: true), findsOneWidget);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Phone *', findRichText: true), findsNothing);
    });

    testWidgets('phone on the profile: read-only; no phone when not asked', (tester) async {
      await open(tester, [stateJson(me: member(phoneMissing: false), requirePhone: true)]);
      expect(find.text('+14165550123'), findsOneWidget);
      expect(find.text('Saved to your profile'), findsNothing);
    });
  });

  testWidgets('sends the answers; name and phone only when missing; device passed', (
    tester,
  ) async {
    final api = await open(tester, [
      stateJson(me: member(nameMissing: true), requirePhone: true),
    ]);
    await tester.enterText(textIn(find.byKey(const ValueKey('field-full_name'))), ' Zeynep  Aksoy ');
    await tester.enterText(textIn(find.byKey(const ValueKey('field-phone'))), '416 555 0123');
    await fillRequired(tester);
    await tester.tap(find.descendant(of: question('Workshops'), matching: find.text('Sports')));
    await tester.pump();
    await send(tester);

    expect(api.registerCalls.single, {
      'event': eventId,
      'version': 'v1',
      'answers': {'q_SHRT2222': 'Danforth CI', 'q_MLTP2222': ['o_BBBBB3'], 'q_YSN22222': false},
      'name': 'Zeynep  Aksoy',
      'phone': '416 555 0123',
      'device': device,
    });
    expect(results, [true]);
  });

  testWidgets('a member with a name and phone sends neither', (tester) async {
    final api = await open(tester, [stateJson(me: member(phoneMissing: false), requirePhone: true)]);
    await fillRequired(tester);
    await send(tester);
    expect((api.registerCalls.single['name'], api.registerCalls.single['phone']), (null, null));
  });

  testWidgets('empty: every required field says why, nothing is sent', (tester) async {
    final api = await open(tester, [
      stateJson(me: member(nameMissing: true), requirePhone: true),
    ]);
    await send(tester);
    expect(api.registerCalls, isEmpty);
    expect(find.text('Check the fields below.'), findsOneWidget);
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter your phone number.'), findsOneWidget);
    expect(find.text('This question is required.'), findsNWidgets(2));
  });

  testWidgets("the server's invalid_answers: each message under its field", (tester) async {
    final api = await open(tester, [stateJson(me: member())]);
    api.registerErrors.add(const PostgrestException(
      code: '22023',
      message: 'invalid_answers',
      details: '{"q_SHRT2222": "too_long", "q_PHNE2222": "invalid_phone"}',
    ));
    await fillRequired(tester);
    await send(tester);
    expect(find.text('This answer is too long.'), findsOneWidget);
    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('invalid _answers: the update banner', (tester) async {
    final api = await open(tester, [stateJson(me: member())]);
    api.registerErrors.add(const PostgrestException(
      code: '22023', message: 'invalid_answers', details: '{"_answers": "too_long"}',
    ));
    await fillRequired(tester);
    await send(tester);
    expect(find.text("Your answers couldn't be sent. Update the app and try again."), findsOneWidget);
  });

  testWidgets('form_changed: refetched, answers that still fit kept, banner', (tester) async {
    final changed = form();
    // The yes/no question is gone; a new required question appears.
    (changed['questions']! as List)
      ..removeWhere((q) => (q as Map)['id'] == 'q_YSN22222')
      ..add({'id': 'q_NEWW2222', 'type': 'short_text', 'required': false, 'label': {'tr': 'Yeni', 'en': 'New'}});
    final api = await open(tester, [
      stateJson(me: member()),
      stateJson(me: member(), formJson: changed),
    ]);
    api.registerErrors.add(const PostgrestException(code: 'P0001', message: 'form_changed'));
    await fillRequired(tester);
    await send(tester);
    expect(api.stateCalls, 2);
    expect(find.text('The form was updated. Check it and send again.'), findsOneWidget);
    expect(find.text('New', findRichText: true), findsOneWidget);
    expect(find.text('Shuttle? *', findRichText: true), findsNothing);
    expect(find.text('  Danforth CI '), findsOneWidget);
    await send(tester);
    expect(api.registerCalls.last['answers'], {'q_SHRT2222': 'Danforth CI'});
    expect(results, [true]);
  });

  testWidgets('offline: banner, answers kept, nothing lost', (tester) async {
    final api = await open(tester, [stateJson(me: member())]);
    api.registerErrors.add(Exception('socket'));
    await fillRequired(tester);
    await send(tester);
    expect(find.text('No internet connection. Registering needs one.'), findsOneWidget);
    expect(find.text('  Danforth CI '), findsOneWidget);
    await send(tester);
    expect(api.registerCalls, hasLength(2));
    expect(results, [true]);
  });

  for (final (message, code) in [
    ('full', 'P0001'),
    ('deadline_passed', 'P0001'),
    ('registration_closed', 'P0001'),
    ('registration_unavailable', 'P0001'),
    ('event_not_found', 'P0002'),
    ('no_profile', 'P0002'),
  ]) {
    testWidgets('$message: back to the event page', (tester) async {
      final api = await open(tester, [stateJson(me: member())]);
      api.registerErrors.add(PostgrestException(code: code, message: message));
      await fillRequired(tester);
      await send(tester);
      expect(results, [false]);
    });
  }

  testWidgets('42501: the sign-in screen', (tester) async {
    final api = await open(tester, [stateJson(me: member())]);
    api.registerErrors.add(const PostgrestException(code: '42501', message: 'not signed in'));
    await fillRequired(tester);
    await send(tester);
    expect(find.text('SIGN IN SCREEN'), findsOneWidget);
  });

  testWidgets('leaving and coming back keeps the answers (D8); success clears them', (
    tester,
  ) async {
    await open(tester, [stateJson(me: member())]);
    await fillRequired(tester);
    GoRouter.of(tester.element(find.byType(RegistrationScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('  Danforth CI '), findsOneWidget);
    await send(tester);
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('  Danforth CI '), findsNothing);
  });

  testWidgets('a required question of an unknown type: sending is disabled (D6)', (tester) async {
    final f = form();
    (f['questions']! as List).add({'id': 'q_FILE2222', 'type': 'file', 'required': true, 'label': {'tr': 'Dosya'}});
    await open(tester, [stateJson(me: member(), formJson: f)]);
    expect(find.text('Update the app to answer this question.'), findsOneWidget);
    expect(find.byKey(const Key('registration-submit')), findsNothing);
  });

  testWidgets('Turkish', (tester) async {
    await open(tester, [stateJson(me: member())], locale: const Locale('tr'));
    expect(find.text('Bilgilerin'), findsOneWidget);
    expect(find.text('Kaydı gönder'), findsOneWidget);
    expect(find.text('Kayıt uygulamadan iptal edilemez.'), findsOneWidget);
  });
}
