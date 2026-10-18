import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/donations/donation_funds.dart';
import 'package:myt_flutter/features/donations/donate_sheet.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/donations_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';

void main() {
  const funds = [
    DonationFund(slug: 'zekat', title: 'Zekât'),
    DonationFund(slug: 'sadaka', title: 'Sadaka'),
  ];

  /// Opens the sheet the way the Donate pill and the Donate row do.
  Future<void> open(
    WidgetTester tester,
    List<DonationFund> funds, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialDonationFundsProvider.overrideWithValue(funds)],
        child: MaterialApp(
          theme: appLightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDonateSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the funds in order, then All donation options', (
    tester,
  ) async {
    await open(tester, funds);
    expect(find.text('Donate'), findsOneWidget);
    expect(find.text('Opens our website in Safari'), findsOneWidget);
    final zekat = tester.getTopLeft(find.text('Zekât')).dy;
    final sadaka = tester.getTopLeft(find.text('Sadaka')).dy;
    final all = tester.getTopLeft(find.text('All donation options')).dy;
    expect(zekat, lessThan(sadaka));
    expect(sadaka, lessThan(all));
  });

  testWidgets('with no funds only All donation options shows', (tester) async {
    await open(tester, const []);
    expect(find.text('All donation options'), findsOneWidget);
    expect(find.text('Zekât'), findsNothing);
  });

  testWidgets('fund titles stay as written in other languages', (
    tester,
  ) async {
    await open(tester, funds, locale: const Locale('fr'));
    expect(find.text('Faire un don'), findsOneWidget);
    expect(find.text('Zekât'), findsOneWidget);
    expect(find.text('Toutes les options de don'), findsOneWidget);
  });

  testWidgets('tapping a row closes the sheet', (tester) async {
    await open(tester, funds);
    await tester.tap(find.text('Sadaka'));
    await tester.pumpAndSettle();
    expect(find.text('Opens our website in Safari'), findsNothing);
  });
}
