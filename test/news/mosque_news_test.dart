import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/news/mosque_news.dart';
import 'package:myt_flutter/features/community/screens/news_detail_screen.dart';
import 'package:myt_flutter/features/community/widgets/news_card.dart';
import 'package:myt_flutter/features/prayer/widgets/news_rail.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/mosque_news_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_controls.dart';
import 'package:myt_flutter/ui/components/news_photo.dart';

const _manrope = 'assets/fonts/Manrope-Regular.ttf';
const _id = '11111111-1111-4111-8111-111111111111';
const _url =
    'https://onczqxxdvmmmdcuhmyio.supabase.co/storage/v1/object/public/news-images/$_id/$_id.jpg';
const _photo = {'url': _url, 'fit': 'crop', 'width': 1280, 'height': 1600};
const _row = {
  'id': _id,
  'title': ' Ziyaret ',
  'body': 'Metin',
  'news_date': '2026-10-12',
  'cover': _photo,
  'photos': [_photo],
  'is_featured': true,
};

MosqueNews _news(String id, {bool featured = false, int photos = 0}) => MosqueNews(
      id: id,
      title: 'Haber $id',
      body: 'Birinci paragraf.\n\nİkinci paragraf.',
      date: DateTime.utc(2026, 10, 12),
      cover: const NewsPhoto(url: _url),
      photos: List.filled(photos, const NewsPhoto(url: _url, contain: true)),
      featured: featured,
    );

Widget _app(Widget child, {String locale = 'tr', ThemeMode mode = ThemeMode.light}) =>
    MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: mode,
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

void main() {
  group('parsing', () {
    test('reads a row', () {
      final n = MosqueNews.parse(_row)!;
      expect(n.title, 'Ziyaret');
      expect(n.date, DateTime.utc(2026, 10, 12));
      expect(n.slides.length, 2);
      expect(n.featured, isTrue);
    });

    test('a row without a usable cover is skipped', () {
      expect(MosqueNews.parse({..._row, 'cover': null}), isNull);
      expect(
        MosqueNews.parse({
          ..._row,
          'cover': {..._photo, 'url': 'https://example.com/x.jpg'},
        }),
        isNull,
      );
      expect(parseNewsList([_row, 'x', {..._row, 'title': ' '}]).length, 1);
      expect(parseNewsList('x'), isEmpty);
    });

    test('a photo from another bucket is dropped, fit and alt are read', () {
      final bad = _url.replaceFirst('news-images', 'event-images');
      expect(NewsPhoto.parse({..._photo, 'url': bad}), isNull);
      expect(NewsPhoto.parse({..._photo, 'fit': 'contain'})!.contain, isTrue);
      expect(NewsPhoto.parse(_photo)!.contain, isFalse);
      expect(NewsPhoto.parse({..._photo, 'alt': ' '})!.altText, isNull);
      expect(NewsPhoto.parse({..._photo, 'alt': 'Avlu'})!.altText, 'Avlu');
    });

    test('the rail puts featured first and keeps the order within each', () {
      final order = newsRailOrder([
        _news('a'),
        _news('b', featured: true),
        _news('c'),
        _news('d', featured: true),
      ]);
      expect(order.map((n) => n.id), ['b', 'd', 'a', 'c']);
    });

    test('the news flag is on unless the panel turns it off', () {
      const on = AppFeatures();
      expect(on.news, isTrue);
      expect(AppFeatures.parse({'news': false}, on).news, isFalse);
      expect(AppFeatures.parse({'events': false}, on).news, isTrue);
    });
  });

  group('widgets', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('the rail shows cards, featured first ($mode)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mosqueNewsProvider.overrideWith(
                (ref) async => [_news('a'), _news('b', featured: true)],
              ),
            ],
            child: _app(
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [NewsRail()]),
              ),
              mode: mode,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Camimizden Haberler'), findsOneWidget);
        final cards =
            tester.widgetList<HomeNewsCard>(find.byType(HomeNewsCard)).toList();
        expect(cards.first.item.id, 'b');
        // Several: 88% of the content width, the next one peeking in.
        final first = tester.getRect(find.byType(HomeNewsCard).first);
        expect(first.width, closeTo(350 * NewsRail.peekFraction, 0.5));
        expect(first.width / first.height, greaterThan(1.1));
        expect(tester.getRect(find.byType(HomeNewsCard).at(1)).left, lessThan(390));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('one item fills the content width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mosqueNewsProvider.overrideWith((ref) async => [_news('a')]),
          ],
          child: _app(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [NewsRail()]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(HomeNewsCard));
      expect(card.width, 350);
      expect(find.byType(PageView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail takes no room without news', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosqueNewsProvider.overrideWith((ref) async => [])],
          child: _app(const Column(children: [NewsRail()])),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeNewsCard), findsNothing);
      expect(tester.getSize(find.byType(NewsRail)).height, 0);
    });

    for (final (code, labels) in [
      ('tr', ['Etkinlikler', 'Duyurular', 'Haberler']),
      ('en', ['Events', 'Announcements', 'News']),
      ('fr', ['Événements', 'Annonces', 'Actualités']),
    ]) {
      testWidgets('three segments fit a 390 pt screen ($code)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSegmented(labels: labels, index: 2, onChanged: (_) {}),
            ),
            locale: code,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The test font is blocks, so measure with the bundled Manrope, which
        // is a little wider than the iPhone's system font.
        final font = FontLoader('MeasureManrope')
          ..addFont(rootBundle.load(_manrope));
        await tester.runAsync(font.load);
        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: 'MeasureManrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(painter.width, lessThan((350 - 4) / 3 - 8), reason: label);
        }
      });
    }

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('detail: gallery, dots, date and paragraphs ($mode)', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: _app(NewsDetailScreen(item: _news('a', photos: 2)), mode: mode),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('12 Ekim 2026'), findsOneWidget);
        expect(find.text('Birinci paragraf.'), findsOneWidget);
        expect(find.text('İkinci paragraf.'), findsOneWidget);
        expect(tester.getSize(find.byType(PageView)), const Size(390, 487.5));
        expect(find.bySemanticsLabel('1 / 3'), findsOneWidget);
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('viewer: one finger swipes, two fingers do not', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final photos = List.filled(3, const NewsPhoto(url: _url));
      await tester.pumpWidget(_app(NewsViewer(photos: photos, start: 0, title: 'T')));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 / 3'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 / 3'), findsOneWidget);

      final a = await tester.startGesture(const Offset(150, 400));
      final b = await tester.startGesture(const Offset(250, 400), pointer: 7);
      await tester.pump();
      await a.moveBy(const Offset(-90, 0));
      await b.moveBy(const Offset(90, 0));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(find.textContaining('2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sığdır draws the blurred fill, a crop does not', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 200,
            child: Column(
              children: [NewsPhotoFrame(photo: NewsPhoto(url: _url, contain: true))],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('poster-backdrop')), findsOneWidget);
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 200,
            child: Column(children: [NewsPhotoFrame(photo: NewsPhoto(url: _url))]),
          ),
        ),
      );
      expect(find.byKey(const Key('poster-backdrop')), findsNothing);
    });
  });
}
