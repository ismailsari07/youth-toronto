import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/features/community/widgets/event_contribution_card.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/theme/app_theme.dart';

void main() {
  YouthEvent parse(Map<String, dynamic> extra) => YouthEvent.fromJson({
        'id': 'e',
        'title': 'Gençlik Buluşması',
        'date_time': '2026-09-30T23:30:00+00:00',
        'category': 'community',
        'recurrence': 'none',
        ...extra,
      });

  group('YouthEvent', () {
    test('a row from before the migration has no box', () {
      final e = parse({});
      expect(e.hasContribution, isFalse);
      expect(e.contributionPhone, isNull);
    });

    test('no phone means no box, whatever else is set', () {
      expect(parse({'contribution_heading': 'Katkı?'}).hasContribution, isFalse);
      expect(parse({'contribution_phone': '  ', 'contribution_heading': 'Katkı?'}).hasContribution, isFalse);
      expect(parse({'contribution_phone': '416 555 0142'}).hasContribution, isFalse);
    });

    test('reads all four fields', () {
      final e = parse({
        'contribution_phone': '416 555 0142',
        'contribution_heading': 'Katkı?',
        'contribution_text': 'Metin',
        'contribution_name': 'Ali',
      });
      expect(e.hasContribution, isTrue);
      expect(e.contributionPhone, '416 555 0142');
      expect(e.contributionHeading, 'Katkı?');
      expect(e.contributionText, 'Metin');
      expect(e.contributionName, 'Ali');
    });
  });

  test('the stored phone format dials correctly', () {
    expect(telUri('416 555 0142'), 'tel:+14165550142');
  });

  group('EventContributionCard', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      ThemeData? theme,
      Locale locale = const Locale('en'),
    }) =>
        tester.pumpWidget(
          MaterialApp(
            theme: theme ?? appLightTheme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: child),
          ),
        );

    for (final (mode, theme) in [('light', appLightTheme), ('dark', appDarkTheme)]) {
      testWidgets('shows every field, tap calls ($mode)', (tester) async {
        var calls = 0;
        await pump(
          tester,
          EventContributionCard(
            heading: 'Katkıda bulunmak ister misiniz?',
            text: 'Yemek veya ikram katkısı için arayabilirsiniz',
            phone: '416 555 0142',
            name: 'Gençlik Kolu',
            onCall: () => calls++,
          ),
          theme: theme,
        );
        expect(find.text('Katkıda bulunmak ister misiniz?'), findsOneWidget);
        expect(find.text('Yemek veya ikram katkısı için arayabilirsiniz'), findsOneWidget);
        expect(find.text('Gençlik Kolu'), findsOneWidget);
        await tester.tap(find.text('416 555 0142'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      });
    }

    for (final (code, label) in [('en', 'Tap to call'), ('tr', 'Aramak için dokunun'), ('fr', 'Touchez pour appeler')]) {
      testWidgets('no contact name: translated hint, no text ($code)', (tester) async {
        await pump(
          tester,
          EventContributionCard(heading: 'Katkı?', phone: '416 555 0142', onCall: () {}),
          locale: Locale(code),
        );
        expect(find.text(label), findsOneWidget);
      });
    }
  });
}
