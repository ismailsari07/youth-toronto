import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_refresh.dart';
import 'package:myt_flutter/features/prayer/screens/prayer_home_screen.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/donations_provider.dart';
import 'package:myt_flutter/shared/providers/events_news_provider.dart';
import 'package:myt_flutter/shared/providers/prayer_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pull on Prayer reschedules the reminders and rewrites the widget, so a
/// corrected time reaches both without waiting for a silent push.
void main() {
  setUp(() {
    initMosqueTime();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => prayerRefresh = refreshPrayerSchedules);

  testWidgets('pull to refresh reschedules reminders and the widget', (tester) async {
    var refreshes = 0;
    prayerRefresh = () async {
      refreshes++;
      return true;
    };
    final today = mosqueNow();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerProvider.overrideWith(
            (ref) async => PrayerCachePayload(
              dailyPrayerTimes: const [
                DailyPrayerItem(name: 'Fajr', time: '05:43', iqamah: '6:45'),
                DailyPrayerItem(name: 'Sunrise', time: '07:11'),
                DailyPrayerItem(name: 'Dhuhr', time: '1:11', iqamah: '1:45'),
                DailyPrayerItem(name: 'Asr', time: '4:23', iqamah: '4:45'),
                DailyPrayerItem(name: 'Maghrib', time: '7:02', iqamah: '7:02'),
                DailyPrayerItem(name: 'Isha', time: '8:19', iqamah: '8:30'),
              ],
              hijriDate: '23.4.1448',
              gregorianDate: '${today.day}.${today.month}.${today.year}',
            ),
          ),
          eventsProvider.overrideWith((ref) async => const []),
          newsProvider.overrideWith((ref) async => const []),
          initialDonationFundsProvider.overrideWithValue(const []),
        ],
        child: MaterialApp(
          theme: appLightTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: PrayerHomeScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(refreshes, 0);
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshes, 1);
  });
}
