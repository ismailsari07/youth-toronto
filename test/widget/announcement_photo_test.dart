import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/announcement_card.dart';
import 'package:myt_flutter/ui/components/announcement_photo.dart';

void main() {
  Announcement item({String? imageUrl, String? alt}) => Announcement(
    id: 'a1',
    title: 'Kermes',
    description: 'Hafta sonu kermes.',
    imageUrl: imageUrl,
    imageAltText: alt,
    createdAt: DateTime.now(),
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SizedBox(width: 393, child: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('a card without a photo has no image area', (tester) async {
    await pump(tester, AnnouncementCard(item: item()));
    expect(find.byType(AnnouncementPhoto), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('while loading, a 16:9 placeholder carries the alt text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      AnnouncementCard(
        item: item(imageUrl: 'https://example.test/a.jpg', alt: 'Kermes afişi'),
      ),
    );
    final photo = tester.getSize(find.byType(AnnouncementPhoto));
    expect(photo.width / photo.height, closeTo(16 / 9, 0.01));
    expect(find.bySemanticsLabel(RegExp('Kermes afişi')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a photo that fails to load collapses, frame and all', (
    tester,
  ) async {
    // Network images fail in widget tests (HTTP 400).
    await pump(
      tester,
      Column(
        children: [
          AnnouncementPhoto.natural(
            url: 'https://example.test/missing.jpg',
            wrap: (photo) => Padding(
              key: const ValueKey('frame'),
              padding: const EdgeInsets.only(bottom: 12),
              child: photo,
            ),
          ),
        ],
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('frame')), findsNothing);
    expect(find.byIcon(Icons.broken_image), findsNothing);
    expect(tester.getSize(find.byType(AnnouncementPhoto)).height, 0);
  });
}
