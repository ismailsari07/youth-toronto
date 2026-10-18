import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/registration/registration_form.dart';
import 'package:myt_flutter/features/registration/question_fields.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/theme/app_theme.dart';

/// One widget per §10.2 type: what it shows and the value it hands back.
void main() {
  late List<Object?> sent;

  Question question(
    QuestionType type, {
    bool required = false,
    int options = 0,
    num? min,
    num? max,
    bool integer = false,
  }) =>
      Question(
        id: 'q_AAAAAAA2',
        type: type,
        required: required,
        label: const {'tr': 'Soru', 'en': 'Question'},
        min: min,
        max: max,
        integer: integer,
        options: [
          for (var i = 0; i < options; i++) ChoiceOption('o_$i', {'tr': 'Seçenek $i', 'en': 'Option $i'}),
        ],
      );

  Future<void> pump(
    WidgetTester tester,
    Question q, {
    Object? value,
    String? error,
    Locale locale = const Locale('en'),
  }) async {
    sent = [];
    final controller = TextEditingController();
    addTearDown(controller.dispose);
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => QuestionField(
                question: q,
                value: value,
                controller: controller,
                error: error,
                onChanged: (v) => setState(() {
                  sent.add(v);
                  value = v;
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextField field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField));

  testWidgets('label in the device language, asterisk only when required', (tester) async {
    await pump(tester, question(QuestionType.shortText, required: true), locale: const Locale('fr'));
    // No French label: English.
    expect(find.text('Question *', findRichText: true), findsOneWidget);
    expect(tester.getSemantics(find.byType(FieldLabel)).label, contains('Obligatoire'));
    await pump(tester, question(QuestionType.shortText));
    expect(find.text('Question', findRichText: true), findsOneWidget);
    expect(find.text('Question *', findRichText: true), findsNothing);
  });

  testWidgets('short text: one line, 200 max', (tester) async {
    await pump(tester, question(QuestionType.shortText));
    expect((field(tester).maxLines, field(tester).maxLength), (1, 200));
    await tester.enterText(find.byType(TextField), 'Ali');
    expect(sent.last, 'Ali');
  });

  testWidgets('long text: multi-line, 2000 max, counter', (tester) async {
    await pump(tester, question(QuestionType.longText));
    expect(field(tester).maxLength, 2000);
    expect(field(tester).maxLines, greaterThan(1));
    await tester.enterText(find.byType(TextField), 'Merhaba');
    await tester.pump();
    expect(find.text('7/2000'), findsOneWidget);
  });

  testWidgets('number: decimal keyboard and range hint; sends a number', (tester) async {
    await pump(tester, question(QuestionType.number, min: 0.5, max: 10));
    expect(field(tester).keyboardType, const TextInputType.numberWithOptions(decimal: true));
    expect(find.text('Between 0.5 and 10'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2,5');
    expect(sent.last, 2.5);
    await tester.enterText(find.byType(TextField), '');
    expect(sent.last, isNull);
  });

  testWidgets('number, integer: no decimal key, whole-number hint, digits only', (tester) async {
    await pump(tester, question(QuestionType.number, min: 12, max: 18, integer: true));
    expect(field(tester).keyboardType, const TextInputType.numberWithOptions());
    expect(find.text('Between 12 and 18 · Whole number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '15');
    expect(sent.last, 15);
  });

  testWidgets('single choice, up to 6 options: radios', (tester) async {
    await pump(tester, question(QuestionType.singleChoice, options: 6));
    expect(find.text('Option 5'), findsOneWidget);
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(sent.last, 'o_2');
    expect(tester.getSemantics(find.text('Option 2')), containsSemantics(isChecked: true));
  });

  testWidgets('single choice, more than 6 options: a sheet', (tester) async {
    await pump(tester, question(QuestionType.singleChoice, options: 7));
    expect(find.text('Option 0'), findsNothing);
    expect(find.text('Choose'), findsOneWidget);
    await tester.tap(find.byKey(const Key('choice-picker')));
    await tester.pumpAndSettle();
    expect(find.byType(OptionSheet), findsOneWidget);
    await tester.tap(find.text('Option 6'));
    await tester.pumpAndSettle();
    expect(sent.last, 'o_6');
    expect(find.text('Option 6'), findsOneWidget);
  });

  testWidgets('multiple choice: checkboxes, list in form order, none = null', (tester) async {
    await pump(tester, question(QuestionType.multipleChoice, options: 3));
    expect(find.text('Choose all that apply'), findsOneWidget);
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    await tester.tap(find.text('Option 0'));
    await tester.pump();
    expect(sent.last, ['o_0', 'o_2']);
    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(sent.last, isNull);
  });

  testWidgets('yes/no: neither chosen at first; No sends false', (tester) async {
    await pump(tester, question(QuestionType.yesNo, required: true));
    for (final label in ['Yes', 'No']) {
      expect(tester.getSemantics(find.text(label)), containsSemantics(isSelected: false));
    }
    await tester.tap(find.text('No'));
    await tester.pump();
    expect(sent.last, false);
    expect(tester.getSemantics(find.text('No')), containsSemantics(isSelected: true));
  });

  testWidgets('date: the system picker, sent as YYYY-MM-DD, shown with the year', (tester) async {
    await pump(tester, question(QuestionType.date), value: '2026-10-18');
    expect(find.text('18 October 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('date-picker')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(sent.last, '2026-10-20');
  });

  testWidgets('date in Turkish', (tester) async {
    await pump(tester, question(QuestionType.date), locale: const Locale('tr'));
    expect(find.text('Tarih seç'), findsOneWidget);
  });

  testWidgets('phone: phone keyboard, sent as typed', (tester) async {
    await pump(tester, question(QuestionType.phone));
    expect(field(tester).keyboardType, TextInputType.phone);
    await tester.enterText(find.byType(TextField), '(416) 555-0123');
    expect(sent.last, '(416) 555-0123');
  });

  testWidgets('unknown type: asks for an update (D6)', (tester) async {
    await pump(tester, question(QuestionType.unknown, required: true));
    expect(find.text('Update the app to answer this question.'), findsOneWidget);
  });

  testWidgets('an error shows under the field', (tester) async {
    await pump(tester, question(QuestionType.shortText), error: 'This question is required.');
    expect(find.byType(FieldError), findsOneWidget);
    expect(find.text('This question is required.'), findsOneWidget);
  });

  test('number text → answer', () {
    expect(parseNumberAnswer(' 12 '), 12);
    expect(parseNumberAnswer('2,5'), 2.5);
    expect(parseNumberAnswer(''), isNull);
    expect(parseNumberAnswer('-'), '-');
  });
}
