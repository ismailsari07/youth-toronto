import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_field.dart';
import 'package:myt_flutter/ui/components/app_text_input.dart';

/// The keyboard always has a way out (1.2.1, TestFlight bug): tap outside,
/// return, the iOS Done bar, and dragging the scroll view.
void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  late List<String> taps;
  late TextEditingController email, password, phone, note, dob;

  setUp(() {
    taps = [];
    email = TextEditingController();
    password = TextEditingController();
    phone = TextEditingController();
    note = TextEditingController();
    dob = TextEditingController();
  });

  /// Email, a read-only date, phone, a multi-line note, password (last), and a
  /// button, in a list that dismisses on drag.
  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(375 * 2, 667 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (_, child) => KeyboardAccessoryHost(child: child!),
        home: Scaffold(
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppField(key: const Key('email'), label: 'Email', controller: email),
              AppField(
                key: const Key('dob'),
                label: 'Born',
                controller: dob,
                readOnly: true,
                onTap: () {},
              ),
              AppField(
                key: const Key('phone'),
                label: 'Phone',
                controller: phone,
                keyboardType: TextInputType.phone,
              ),
              AppTextInput(key: const Key('note'), controller: note, maxLines: 4),
              AppField(
                key: const Key('password'),
                label: 'Password',
                controller: password,
                obscure: true,
                last: true,
                onSubmit: () => taps.add('submit'),
              ),
              TextButton(onPressed: () => taps.add('button'), child: const Text('BUTTON')),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
  }

  Finder input(String key) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(EditableText));
  bool focused(WidgetTester tester, String key) =>
      tester.widget<EditableText>(input(key)).focusNode.hasPrimaryFocus;
  // Not by key: a field scrolled out of the lazy list is gone.
  bool anyFocused(WidgetTester tester) =>
      FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  Future<void> focus(WidgetTester tester, String key) async {
    await tester.tap(input(key));
    await tester.pumpAndSettle();
    expect(focused(tester, key), isTrue);
  }

  /// The keyboard is up: 216 pt, an iPhone SE's.
  void keyboardUp(WidgetTester tester) =>
      tester.view.viewInsets = const FakeViewPadding(bottom: 216 * 2);

  group('tap outside', () {
    testWidgets('unfocuses', (tester) async {
      await pump(tester);
      await focus(tester, 'email');
      await tester.tapAt(const Offset(370, 600));
      await tester.pump();
      expect(anyFocused(tester), isFalse);
    }, variant: ios);

    testWidgets("unfocuses and the button still gets its tap", (tester) async {
      await pump(tester);
      await focus(tester, 'note');
      await tester.tap(find.text('BUTTON'));
      await tester.pump();
      expect(anyFocused(tester), isFalse);
      expect(taps, ['button']);
    }, variant: ios);

    testWidgets('another field takes the focus', (tester) async {
      await pump(tester);
      await focus(tester, 'email');
      await focus(tester, 'phone');
      expect(focused(tester, 'email'), isFalse);
    }, variant: ios);
  });

  testWidgets('dragging the list closes the keyboard (onDrag)', (tester) async {
    await pump(tester);
    await focus(tester, 'email');
    // Starts on the field itself, so it's not a tap outside.
    await tester.drag(input('email'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(anyFocused(tester), isFalse);
  }, variant: ios);

  group('return key', () {
    TextInputAction? action(WidgetTester tester, String key) =>
        tester.widget<EditableText>(input(key)).textInputAction;

    testWidgets('next on one-line fields, done on the last, new line on multi-line', (
      tester,
    ) async {
      await pump(tester);
      expect(action(tester, 'email'), TextInputAction.next);
      expect(action(tester, 'note'), TextInputAction.newline);
      expect(action(tester, 'password'), TextInputAction.done);
    });

    testWidgets('next moves to the next field, skipping read-only ones', (tester) async {
      await pump(tester);
      await focus(tester, 'email');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(focused(tester, 'phone'), isTrue);
    });

    testWidgets('done on the last field submits and closes the keyboard', (tester) async {
      await pump(tester);
      await focus(tester, 'password');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(taps, ['submit']);
      expect(anyFocused(tester), isFalse);
    });
  });

  group('Done bar (iOS)', () {
    Finder bar() => find.byKey(const Key('keyboard-accessory'));

    testWidgets('phone and multi-line fields get it; Done closes the keyboard', (tester) async {
      await pump(tester);
      keyboardUp(tester);
      await focus(tester, 'phone');
      expect(bar(), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.byKey(const Key('keyboard-done')));
      await tester.pumpAndSettle();
      expect(anyFocused(tester), isFalse);
      expect(bar(), findsNothing);

      await focus(tester, 'note');
      expect(bar(), findsOneWidget);
    }, variant: ios);

    testWidgets('sits right on the keyboard; the page clears it', (tester) async {
      await pump(tester);
      keyboardUp(tester);
      await focus(tester, 'phone');
      expect(tester.getBottomLeft(bar()).dy, 667 - 216);
      // The scaffold's body ends above the bar.
      expect(tester.getSize(find.byType(ListView)).height, 667 - 216 - KeyboardAccessoryHost.height);
    }, variant: ios);

    testWidgets('arrows move between fields, skipping read-only ones', (tester) async {
      await pump(tester);
      keyboardUp(tester);
      await focus(tester, 'phone');
      await tester.tap(find.byKey(const Key('keyboard-next')));
      await tester.pumpAndSettle();
      expect(focused(tester, 'note'), isTrue);
      // The bar stays: the note needs it too.
      await tester.tap(find.byKey(const Key('keyboard-previous')));
      await tester.pumpAndSettle();
      expect(focused(tester, 'phone'), isTrue);
      await tester.tap(find.byKey(const Key('keyboard-previous')));
      await tester.pumpAndSettle();
      expect(focused(tester, 'email'), isTrue);
    }, variant: ios);

    testWidgets('not on a one-line text field, nor with the keyboard down', (tester) async {
      await pump(tester);
      keyboardUp(tester);
      await focus(tester, 'email');
      expect(bar(), findsNothing);
      tester.view.resetViewInsets();
      await focus(tester, 'phone');
      expect(bar(), findsNothing);
    }, variant: ios);

    testWidgets('not on Android', (tester) async {
      await pump(tester);
      keyboardUp(tester);
      await focus(tester, 'phone');
      expect(bar(), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('Turkish and French', (tester) async {
      for (final (locale, done) in [(const Locale('tr'), 'Bitti'), (const Locale('fr'), 'Terminé')]) {
        await pump(tester, locale: locale);
        keyboardUp(tester);
        await focus(tester, 'phone');
        expect(find.text(done), findsOneWidget);
        await tester.tap(find.byKey(const Key('keyboard-done')));
        await tester.pumpAndSettle();
      }
    }, variant: ios);
  });

  test('every text field in the app goes through AppTextInput', () {
    final raw = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('app_text_input.dart')) continue;
      if (RegExp(r'\b(TextField|TextFormField|CupertinoTextField)\(').hasMatch(f.readAsStringSync())) {
        raw.add(f.path);
      }
    }
    expect(raw, isEmpty);
  });

  test('every scroll view holding fields closes the keyboard on drag', () {
    final missing = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final s = f.readAsStringSync();
      final hasField = RegExp(r'\b(AppField|AppTextInput|BoxInput)\(').hasMatch(s);
      final scrolls = RegExp(r'\b(ListView|SingleChildScrollView|CustomScrollView)\(').hasMatch(s);
      if (hasField && scrolls && !s.contains('ScrollViewKeyboardDismissBehavior.onDrag')) {
        missing.add(f.path);
      }
    }
    expect(missing, isEmpty);
  });
}
