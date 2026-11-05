import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/prayer_month.dart';
import 'package:myt_flutter/features/prayer/screens/monthly_times_screen.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/formatters.dart';
import 'package:myt_flutter/shared/providers/prayer_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';

import 'hero_identity_row_test.dart' show loadManrope;

PrayerDay _row(
  DateTime day, {
  String? jumuah = '1:00',
  String? diyanetDay,
  String dhuhr = '12:06',
  String hijri = '25.5.1448',
}) =>
    (
      date: mosqueDateKey(day),
      payload: PrayerCachePayload(
        dailyPrayerTimes: [
          const DailyPrayerItem(name: 'Fajr', time: '05:20', iqamah: '06:30'),
          const DailyPrayerItem(name: 'Sunrise', time: '06:51'),
          DailyPrayerItem(name: 'Dhuhr', time: dhuhr, iqamah: '1:00'),
          const DailyPrayerItem(name: 'Asr', time: '2:44', iqamah: '3:00'),
          const DailyPrayerItem(name: 'Maghrib', time: '5:11', iqamah: '5:11'),
          const DailyPrayerItem(name: 'Isha', time: '6:31', iqamah: '7:00'),
        ],
        hijriDate: hijri,
        gregorianDate: diyanetDay ?? diyanetDate(day),
        jumaaPrayerTime: jumuah,
      ),
    );

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting();
    initMosqueTime();
  });

  group('monthDays: real rows, nothing filled', () {
    final thu = DateTime(2026, 11, 5, 9);

    test('from today to the last row, nothing after it', () {
      final days = monthDays([
        for (var i = 0; i < 31; i++) _row(DateTime(2026, 11, 5 + i)),
      ], thu);
      expect(days, hasLength(31));
      expect(days.first.day, DateTime(2026, 11, 5));
      expect(days.last.day, DateTime(2026, 12, 5));
      expect(days.every((d) => d.payload != null), isTrue);
    });

    test('a missing day is listed as missing, not filled from its neighbour', () {
      final days = monthDays([_row(DateTime(2026, 11, 5)), _row(DateTime(2026, 11, 7))], thu);
      expect(days.map((d) => d.day.day), [5, 6, 7]);
      expect(days.map((d) => d.payload != null), [true, false, true]);
    });

    test("today's row missing: today is still first, as missing", () {
      final days = monthDays([_row(DateTime(2026, 11, 6))], thu);
      expect(days.first.day, DateTime(2026, 11, 5));
      expect(days.first.payload, isNull);
    });

    test("a row carrying another day's data counts as missing", () {
      final days = monthDays([
        _row(DateTime(2026, 11, 5)),
        _row(DateTime(2026, 11, 6), diyanetDay: '07.11.2026'),
        _row(DateTime(2026, 11, 7)),
      ], thu);
      expect(days.map((d) => d.payload != null), [true, false, true]);
    });

    test('past rows are not listed; only past rows or none means nothing', () {
      expect(monthDays([_row(DateTime(2026, 11, 4))], thu), isEmpty);
      expect(monthDays(const [], thu), isEmpty);
      expect(monthDays([_row(DateTime(2026, 11, 4)), _row(DateTime(2026, 11, 5))], thu), hasLength(1));
    });

    test('keyed by date: each clock change keeps one row per calendar day', () {
      for (final (start, count) in [(DateTime(2026, 10, 30), 5), (DateTime(2027, 3, 12), 5)]) {
        final rows = [
          for (var i = 0; i < count; i++) _row(DateTime(start.year, start.month, start.day + i)),
        ];
        final days = monthDays(rows, start);
        expect(days.map((d) => mosqueDateKey(d.day)), rows.map((r) => r.date));
        expect(days.every((d) => d.payload != null), isTrue);
      }
    });
  });

  group('PrayerRows: no new call when the rows are already fetched', () {
    late int calls;
    late DateTime clock;
    late Object answer;

    setUp(() {
      calls = 0;
      clock = DateTime(2026, 11, 5, 12);
      answer = [_row(DateTime(2026, 11, 5))];
      PrayerRows.reset();
      PrayerRows.clock = () => clock;
      PrayerRows.load = ({required first, required last}) async {
        calls++;
        final a = answer;
        if (a is Exception) throw a;
        return a as List<PrayerDay>;
      };
    });
    tearDown(PrayerRows.reset);

    test("the reminders' fetch fills it; the view then makes no call", () async {
      await PrayerRows.fetchDays(first: 0, last: PrayerRows.windowLastDay);
      expect(calls, 1);
      expect(await PrayerRows.window(), hasLength(1));
      expect(calls, 1);
    });

    test('a shorter fetch (the widget) is not mistaken for the whole window', () async {
      await PrayerRows.fetchDays(first: -1, last: 14);
      await PrayerRows.window();
      expect(calls, 2);
    });

    test('nothing yet: one call, then none', () async {
      await PrayerRows.window();
      await PrayerRows.window();
      expect(calls, 1);
    });

    test('calls during a fetch share it', () async {
      await Future.wait([
        PrayerRows.fetchDays(first: 0, last: PrayerRows.windowLastDay),
        PrayerRows.window(),
      ]);
      expect(calls, 1);
    });

    test('after 15 minutes it asks again', () async {
      await PrayerRows.window();
      clock = clock.add(PrayerRows.maxAge);
      await PrayerRows.window();
      expect(calls, 2);
    });

    test('a refresh or a prayer_refresh push drops them and tells the view', () async {
      await PrayerRows.window();
      var told = 0;
      void listener() => told++;
      PrayerRows.changed.addListener(listener);
      addTearDown(() => PrayerRows.changed.removeListener(listener));
      PrayerRows.forget();
      expect(told, 1);
      await PrayerRows.window();
      expect(calls, 2);
    });

    test('offline: old rows if there are any, else the failure', () async {
      answer = Exception('offline');
      await expectLater(PrayerRows.window(), throwsException);

      answer = [_row(DateTime(2026, 11, 5))];
      await PrayerRows.window();
      clock = clock.add(PrayerRows.maxAge);
      answer = Exception('offline');
      expect(await PrayerRows.window(), hasLength(1));
    });

    test('an answer from before a forget is not kept', () async {
      final slow = PrayerRows.fetchDays(first: 0, last: PrayerRows.windowLastDay);
      PrayerRows.forget();
      answer = [_row(DateTime(2026, 11, 6)), _row(DateTime(2026, 11, 7))];
      await slow;
      expect(await PrayerRows.window(), hasLength(2));
      expect(calls, 2);
    });
  });

  group('the screen', () {
    final shotDir = Platform.environment['SHOT_DIR'];

    List<PrayerDay> rows() {
      final n = mosqueNow();
      final today = DateTime(n.year, n.month, n.day);
      return [
        for (var i = 0; i < 31; i++)
          if (i != 2)
            _row(
              DateTime(today.year, today.month, today.day + i),
              // Every month name's length, and a time nobody can read.
              hijri: '${(i % 28) + 1}.${(i % 12) + 1}.1448',
              dhuhr: i == 4 ? 'soon' : '12:06',
            ),
      ];
    }

    Future<void> pump(
      WidgetTester tester,
      String lang,
      ThemeMode mode, {
      required Future<List<PrayerDay>> Function() load,
      GlobalKey? boundary,
      double width = 390,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width * 2, 1000 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: ProviderScope(
            overrides: [prayerMonthProvider.overrideWith((ref) => load())],
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(textScale),
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: appLightTheme,
                darkTheme: appDarkTheme,
                themeMode: mode,
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const MonthlyTimesScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    for (final lang in const ['en', 'tr', 'fr']) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('$lang ${mode.name}: fits 390 pt, nothing cut', (tester) async {
          final problems = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) => problems.add(d.exceptionAsString().split('\n').first);
          addTearDown(() => FlutterError.onError = previous);
          final boundary = GlobalKey();
          await pump(tester, lang, mode, load: () async => rows(), boundary: boundary);

          void visit(RenderObject o) {
            if (o is RenderParagraph) {
              final oneLine = o.maxLines == 1 || !o.softWrap;
              if (o.didExceedMaxLines ||
                  (oneLine && o.getMaxIntrinsicWidth(double.infinity) > o.size.width + 0.5)) {
                problems.add('cut: "${o.text.toPlainText()}"');
              }
            }
            o.visitChildren(visit);
          }

          visit(tester.renderObject(find.byKey(boundary)));

          if (shotDir != null) {
            final png = await tester.runAsync(() async {
              final render = tester.renderObject(find.byKey(boundary)) as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              return bytes!.buffer.asUint8List();
            });
            File('$shotDir/monthly_${lang}_${mode.name}.png').writeAsBytesSync(png!);
          }
          FlutterError.onError = previous;
          expect(problems, isEmpty);
        });
      }

      testWidgets('$lang: Friday, a missing day and the language\'s clock', (tester) async {
        await pump(tester, lang, ThemeMode.light, load: () async => rows());
        final l = lookupAppLocalizations(Locale(lang));
        expect(find.text(l.monthlyMissingDay), findsOneWidget);
        expect(find.text(l.monthlyJumuahAt(clockText(lang, 13, 0))), findsWidgets);
        expect(find.text(clockText(lang, 5, 20)), findsWidgets);
        expect(find.text(clockText(lang, 18, 31)), findsWidgets);
        // Nothing listed after the last row, and it is named.
        final n = mosqueNow();
        final last = DateTime(n.year, n.month, n.day + 30);
        expect(find.text(l.monthlyLastDay(longDate(l, last))), findsOneWidget);
      });
    }

    testWidgets('a time that can\'t be read is a dash, never its raw text', (tester) async {
      await pump(tester, 'en', ThemeMode.light, load: () async => rows());
      expect(find.text('soon'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('fits at 1.3× text and on an iPhone SE', (tester) async {
      final problems = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => problems.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = previous);
      await pump(tester, 'fr', ThemeMode.light, load: () async => rows(), width: 375, textScale: 2);
      FlutterError.onError = previous;
      expect(problems, isEmpty);
    });

    testWidgets('the prayer names follow the sideways scroll', (tester) async {
      await pump(tester, 'tr', ThemeMode.light, load: () async => rows());
      final head = find.text('Yatsı');
      expect(tester.getTopLeft(head).dx, greaterThan(390));
      await tester.drag(find.text('05:20').first, const Offset(-300, 0));
      await tester.pump();
      expect(tester.getTopLeft(head).dx, lessThan(390));
      // The dates stay in view.
      expect(tester.getTopLeft(find.textContaining('1448').first).dx, lessThan(40));
    });

    testWidgets('failed or empty: says so, offers a retry, shows no times', (tester) async {
      for (final load in <Future<List<PrayerDay>> Function()>[
        () async => throw Exception('offline'),
        () async => const [],
      ]) {
        await pump(tester, 'en', ThemeMode.light, load: load);
        await tester.pump(const Duration(milliseconds: 50));
        final l = lookupAppLocalizations(const Locale('en'));
        expect(find.text(l.timesUnavailable), findsOneWidget);
        expect(find.text(l.tryAgain), findsOneWidget);
        expect(find.textContaining('AM'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
