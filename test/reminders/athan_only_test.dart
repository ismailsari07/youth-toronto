import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/reminder_settings.dart';
import 'package:myt_flutter/features/prayer/widgets/reminders_sheet.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/reminders_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';

class _On extends ReminderSettingsNotifier {
  @override
  Future<ReminderSettings> build() async => const ReminderSettings();
}

/// Reminders fire at the athan only: the choice is gone from every language
/// and from every place that showed it.
void main() {
  for (final lang in const ['en', 'tr', 'fr']) {
    test('$lang: no string offers or says "5 minutes before"', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final key in const [
        'remindersNotifyMe',
        'notifyAtAthan',
        'notifyBeforeIqamah',
        'remindersSummaryIqamah',
        'reminderIqamahSoon',
        'reminderJumuahSoon',
        'reminderJumuahNow',
      ]) {
        expect(arb.containsKey(key), isFalse, reason: key);
      }
      final before = RegExp(r"5 (min|dakika|dk)", caseSensitive: false);
      final found = arb.entries
          .where((e) => !e.key.startsWith('@') && e.value is String && before.hasMatch(e.value as String))
          .map((e) => e.key);
      expect(found, isEmpty);
    });

    testWidgets('$lang: the sheet has prayers and sound, and no timing choice', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final l = lookupAppLocalizations(Locale(lang));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderSettingsProvider.overrideWith(_On.new),
            athanBundledProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp(
            theme: appLightTheme,
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(onPressed: () => showRemindersSheet(context), child: const Text('open')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(l.notificationSound), findsOneWidget);
      expect(find.text(l.soundStandard), findsOneWidget);
      expect(find.text(l.remindersPrayers), findsOneWidget);
      expect(remindersSummary(l, const ReminderSettings()), l.remindersSummaryAthan);
      expect(find.textContaining(RegExp('5 (min|dakika|dk)')), findsNothing);
    });
  }

  test('nothing in the app or in Siri still knows the old option', () {
    final files = [
      ...Directory('lib').listSync(recursive: true),
      ...Directory('ios/Runner/Siri').listSync(),
      File('ios/PrayerWidget/PrayerWidget.swift'),
    ].whereType<File>().where((f) => f.path.endsWith('.dart') || f.path.endsWith('.swift'));
    final bad = [
      for (final f in files)
        if (RegExp(r'beforeIqamah|ReminderTiming|setTiming').hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(bad, isEmpty);
  });
}
