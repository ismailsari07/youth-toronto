import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myt_flutter/features/registration/question_fields.dart';
import 'package:myt_flutter/features/registration/registration_screen.dart';
import 'package:myt_flutter/ui/components/app_scaffolding.dart';
import 'package:myt_flutter/ui/components/app_text_input.dart';
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
    Size size = const Size(430, 3200),
  }) async {
    tester.view.physicalSize = size * 3;
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

  group('keyboard on an iPhone SE', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
    const se = Size(375, 667);
    const keyboard = 216.0;

    Future<FakeRegistrationApi> openSe(WidgetTester tester) async {
      final api = await open(
        tester,
        [stateJson(me: member(nameMissing: true), requirePhone: true)],
        size: se,
      );
      tester.view.padding = const FakeViewPadding(top: 20 * 3);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
      await tester.pumpAndSettle();
      return api;
    }

    Future<void> focus(WidgetTester tester, Finder field) async {
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
    }

    bool typing() =>
        FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null;

    Rect visible(WidgetTester tester) => Rect.fromLTRB(
          0,
          tester.getBottomLeft(find.byType(PlainNavBar)).dy,
          se.width,
          tester.getTopLeft(find.byType(StickyBottomBar)).dy,
        );

    testWidgets('the last field (multi-line) and Send stay above the keyboard and the bar', (
      tester,
    ) async {
      await openSe(tester);
      final note = textIn(question('Note'));
      await focus(tester, note);
      expect(find.byKey(const Key('keyboard-accessory')), findsOneWidget);
      final barTop = se.height - keyboard - KeyboardAccessoryHost.height;
      expect(tester.getTopLeft(find.byKey(const Key('keyboard-accessory'))).dy, barTop);
      // The no-cancel line makes room while typing.
      expect(find.text("A registration can't be cancelled in the app."), findsNothing);
      // Send rides on top of the Done bar, whole.
      final submit = tester.getRect(find.byKey(const Key('registration-submit')));
      expect(submit.bottom, lessThanOrEqualTo(barTop));
      expect(submit.top, greaterThan(tester.getBottomLeft(find.byType(PlainNavBar)).dy));
      // The focused field's top line is between the nav bar and Send.
      final field = tester.getRect(note);
      final area = visible(tester);
      expect(field.top, greaterThanOrEqualTo(area.top));
      expect(field.bottom, lessThanOrEqualTo(area.bottom));
    }, variant: ios);

    testWidgets('a field near the top stays visible too', (tester) async {
      await openSe(tester);
      final age = textIn(question('Age'));
      await focus(tester, age);
      final field = tester.getRect(age);
      final area = visible(tester);
      expect(field.top, greaterThanOrEqualTo(area.top));
      expect(field.bottom, lessThanOrEqualTo(area.bottom));
      // A number pad: the Done bar closes it.
      await tester.tap(find.byKey(const Key('keyboard-done')));
      await tester.pumpAndSettle();
      expect(typing(), isFalse);
    }, variant: ios);

    testWidgets('dragging the form closes the keyboard', (tester) async {
      await openSe(tester);
      final school = textIn(question('School *'));
      await focus(tester, school);
      expect(typing(), isTrue);
      await tester.drag(school, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(typing(), isFalse);
    }, variant: ios);

    testWidgets('tapping an option while typing closes the keyboard and picks it', (
      tester,
    ) async {
      await openSe(tester);
      await focus(tester, textIn(question('School *')));
      final no = find.descendant(of: question('Shuttle? *'), matching: find.text('No'));
      await tester.ensureVisible(no);
      await tester.pumpAndSettle();
      // ensureVisible scrolls programmatically: still typing.
      expect(typing(), isTrue);
      await tester.tap(no);
      await tester.pumpAndSettle();
      expect(typing(), isFalse);
      expect(tester.getSemantics(no), containsSemantics(isSelected: true));
    }, variant: ios);

    testWidgets('return: Next through the details, Done only on the last text field', (
      tester,
    ) async {
      await openSe(tester);
      TextInputAction? action(Finder f) =>
          tester.widget<EditableText>(find.descendant(of: f, matching: find.byType(EditableText))).textInputAction;
      expect(action(find.byKey(const ValueKey('field-full_name'))), TextInputAction.next);
      expect(action(question('School *')), TextInputAction.next);
      expect(action(question('Note')), TextInputAction.newline);
      await focus(tester, textIn(find.byKey(const ValueKey('field-full_name'))));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final phone = find.descendant(
        of: find.byKey(const ValueKey('field-phone')),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(phone).focusNode.hasPrimaryFocus, isTrue);
    }, variant: ios);
  });

  testWidgets('Turkish', (tester) async {
    await open(tester, [stateJson(me: member())], locale: const Locale('tr'));
    expect(find.text('Bilgilerin'), findsOneWidget);
    expect(find.text('Kaydı gönder'), findsOneWidget);
    expect(find.text('Kayıt uygulamadan iptal edilemez.'), findsOneWidget);
  });
}
