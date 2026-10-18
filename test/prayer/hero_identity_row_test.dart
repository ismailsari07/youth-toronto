import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/features/donations/donate_sheet.dart';
import 'package:myt_flutter/features/prayer/widgets/hero_identity_row.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/donations_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';

/// The bundled Manrope (the app's fallback face), so widths are real text
/// widths instead of the test font's squares. iOS draws SF Pro, which is
/// narrower than Manrope, so a fit here is a fit on the phone.
Future<void> loadManrope() async {
  // Under the app's own family names too: tests don't use the fallback list.
  for (final family in ['Manrope', kFontText, kFontDisplay]) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Manrope-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(loadManrope);

  /// The row as the hero lays it out: 20 pt padding each side of a phone
  /// [width] wide, on the hero's colour.
  Future<void> pump(
    WidgetTester tester, {
    required String lang,
    double width = 375,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = Size(width * 2, 667 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialDonationFundsProvider.overrideWithValue(const [])],
        child: MaterialApp(
          theme: theme ?? appLightTheme,
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            backgroundColor: const Color(0xFF0F1A2C),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: const Align(
                alignment: Alignment.topCenter,
                child: HeroIdentityRow(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder pill() => find.byKey(const Key('donate-pill'));

  /// How much the one-line organisation name is shrunk to fit (1 = not).
  double nameScale(WidgetTester tester) {
    final text = find.byKey(const Key('hero-organisation'));
    final natural = tester.renderObject<RenderParagraph>(text).size.width;
    final fitted = tester.getSize(
      find.ancestor(of: text, matching: find.byType(FittedBox)).first,
    );
    return fitted.width / natural;
  }

  for (final (lang, label) in [
    ('tr', 'Bağış yap'),
    ('en', 'Donate'),
    ('fr', 'Donner'),
  ]) {
    testWidgets('$lang: the pill shows "$label" in full on an iPhone SE, '
        'and the name and mosque line keep their room', (tester) async {
      await pump(tester, lang: lang);
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The label isn't scaled down inside the pill.
      final labelBox = tester.getSize(find.text(label)).width;
      final natural = tester
          .renderObject<RenderParagraph>(find.text(label))
          .size
          .width;
      expect(labelBox, closeTo(natural, 0.5));

      final mosque = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('hero-mosque-line')),
      );
      expect(mosque.didExceedMaxLines, isFalse);
      // The one-line organisation name shrinks no further than English's
      // (0.82 in Manrope; "Faire un don" took it to 0.66 and cut the line).
      expect(nameScale(tester), greaterThanOrEqualTo(0.8));
    });
  }

  testWidgets('tap target at least 44 pt, semantic label is the full phrase', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, lang: 'fr');
    final target = tester.getSize(
      find.ancestor(of: pill(), matching: find.byType(ConstrainedBox)).first,
    );
    expect(target.height, greaterThanOrEqualTo(44));
    expect(target.width, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(find.byType(DonatePill)),
      matchesSemantics(label: 'Faire un don', isButton: true),
    );
    handle.dispose();
  });

  for (final (name, theme) in [
    ('light', appLightTheme),
    ('dark', appDarkTheme),
  ]) {
    testWidgets('$name: tapping the pill opens the donate sheet', (
      tester,
    ) async {
      await pump(tester, lang: 'en', theme: theme);
      expect(find.byType(DonateSheet), findsNothing);
      await tester.tap(pill());
      await tester.pumpAndSettle();
      expect(find.byType(DonateSheet), findsOneWidget);
      expect(find.text('All donation options'), findsOneWidget);
    });
  }
}
