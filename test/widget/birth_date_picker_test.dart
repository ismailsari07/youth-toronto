import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/birth_date_picker.dart';

void main() {
  for (final (lang, ok) in const [('en', 'OK'), ('tr', 'Tamam'), ('fr', 'OK')]) {
    testWidgets('$lang: opens on the years and goes back to 1920', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DateTime? picked;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showBirthDatePicker(context),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(YearPicker), findsOneWidget);
      final grid = find.descendant(of: find.byType(YearPicker), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('1920'), -300, scrollable: grid);
      await tester.pumpAndSettle();
      expect(find.text('1919'), findsNothing);

      await tester.tap(find.text('1920'));
      await tester.pumpAndSettle();
      expect(find.byType(YearPicker), findsNothing, reason: 'on to the calendar');
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(picked?.year, 1920);
      expect(picked?.day, 15);
    });
  }

  testWidgets('no future year is offered', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showBirthDatePicker(context, initial: DateTime(2200)),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('${DateTime.now().year + 1}'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
