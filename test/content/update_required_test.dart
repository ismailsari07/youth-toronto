import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/features/update/screens/update_required_screen.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';

void main() {
  const store = 'https://apps.apple.com/ca/app/id1234567890';

  ContentBundle bundle({
    String min = '1.0.1',
    String? appStore = store,
    ContentSource source = ContentSource.cache,
  }) => ContentBundle.parse(
    {
      'content': {
        'app_config': {'min_supported_version': min},
        'links': {'app_store': ?appStore},
      },
    },
    fallback: ContentBundle.empty,
    source: source,
  );

  bool requiresUpdate(ContentBundle content, String? version) {
    final c = ProviderContainer(
      overrides: [
        initialContentProvider.overrideWithValue(content),
        appVersionProvider.overrideWithValue(version),
      ],
    );
    addTearDown(c.dispose);
    return c.read(updateRequiredProvider);
  }

  test('1.0.0 below a 1.0.1 minimum is blocked; 1.0.1 is not', () {
    expect(requiresUpdate(bundle(), '1.0.0'), isTrue);
    expect(requiresUpdate(bundle(), '1.0.1'), isFalse);
  });

  test('never blocks without a version, a store link, or real content', () {
    expect(requiresUpdate(bundle(), null), isFalse);
    expect(requiresUpdate(bundle(appStore: null), '1.0.0'), isFalse);
    expect(
      requiresUpdate(bundle(source: ContentSource.defaults), '1.0.0'),
      isFalse,
    );
  });

  testWidgets('the screen says so in Turkish and offers the App Store', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialContentProvider.overrideWithValue(bundle())],
        child: const MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: UpdateRequiredScreen(),
        ),
      ),
    );
    expect(find.text('Güncelleme gerekli'), findsOneWidget);
    expect(find.text("App Store'u aç"), findsOneWidget);
  });
}
