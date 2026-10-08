import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/ui/components/emergency_banner.dart';

void main() {
  ContentBundle withBanner(Map<String, Object?>? banner) => ContentBundle.parse(
    {
      'content': {'app_banner': ?banner},
    },
    fallback: ContentBundle.empty,
    source: ContentSource.cache,
  );

  Future<void> pump(
    WidgetTester tester,
    ContentBundle content, {
    Locale locale = const Locale('fr'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialContentProvider.overrideWithValue(content)],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: EmergencyBanner()),
        ),
      ),
    );
  }

  const text = {'tr': 'Cuma namazı 13:30', 'en': "Jumu'ah at 1:30"};

  testWidgets('an active banner shows, in English when French is missing', (
    tester,
  ) async {
    await pump(
      tester,
      withBanner({'enabled': true, 'tone': 'urgent', 'text': text}),
    );
    expect(find.text("Jumu'ah at 1:30"), findsOneWidget);
  });

  testWidgets('a banner that ended or is off shows nothing', (tester) async {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    await pump(
      tester,
      withBanner({
        'enabled': true,
        'tone': 'info',
        'text': text,
        'ends_at': past.toUtc().toIso8601String(),
      }),
    );
    expect(find.byType(Text), findsNothing);

    await pump(
      tester,
      withBanner({'enabled': false, 'tone': 'info', 'text': text}),
    );
    expect(find.byType(Text), findsNothing);

    await pump(tester, withBanner(null));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('it disappears on its own at ends_at', (tester) async {
    final soon = DateTime.now().add(const Duration(seconds: 2));
    await pump(
      tester,
      withBanner({
        'enabled': true,
        'tone': 'warning',
        'text': text,
        'ends_at': soon.toUtc().toIso8601String(),
      }),
      locale: const Locale('tr'),
    );
    expect(find.text('Cuma namazı 13:30'), findsOneWidget);
    // The banner reads the real clock; its timer runs on the test's fake one.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Cuma namazı 13:30'), findsNothing);
  });
}
