import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/features/profile/widgets/language_sheet.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/l10n/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's localisation setup around a single Language row, with the
/// device reporting [device].
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeOverrideProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (device, _) =>
          resolveAppLocale(null, device ?? const []),
      home: const Scaffold(body: LanguageRow()),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, {Locale? saved}) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [savedLocaleProvider.overrideWithValue(saved)],
        child: const _Harness(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('follows the device by default', (tester) async {
    await pump(tester);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
  });

  testWidgets('picking Türkçe switches the app and saves the choice',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();

    // The sheet: device language first, then each language in its own name.
    expect(find.text("Langue de l'appareil"), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget); // the row's trailing text
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'tr');
  });

  testWidgets('Device language clears the choice', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'tr'});
    await pump(tester, saved: const Locale('tr'));
    expect(find.text('Dil'), findsOneWidget);

    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cihaz dili'));
    await tester.pumpAndSettle();

    expect(find.text('Langue'), findsOneWidget); // back to the device's French
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), isNull);
  });
}
