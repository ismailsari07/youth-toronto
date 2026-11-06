import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/content/content_repository.dart';
import 'package:myt_flutter/core/event_schedule.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/push/push_api.dart';
import 'package:myt_flutter/core/push/push_prompt.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:myt_flutter/core/reminder_settings.dart';
import 'package:myt_flutter/features/community/screens/announcement_detail_screen.dart';
import 'package:myt_flutter/features/community/screens/community_screen.dart';
import 'package:myt_flutter/features/community/screens/event_detail_screen.dart';
import 'package:myt_flutter/features/donations/donate_sheet.dart';
import 'package:myt_flutter/features/marriage/data/document_check.dart';
import 'package:myt_flutter/features/marriage/data/marriage_application.dart';
import 'package:myt_flutter/features/marriage/marriage_provider.dart';
import 'package:myt_flutter/features/marriage/screens/marriage_gate_screen.dart';
import 'package:myt_flutter/features/marriage/screens/marriage_received_screen.dart';
import 'package:myt_flutter/features/marriage/screens/marriage_status_screen.dart';
import 'package:myt_flutter/features/marriage/screens/marriage_upload_screen.dart';
import 'package:myt_flutter/features/marriage/widgets/withdraw_sheet.dart';
import 'package:myt_flutter/features/prayer/screens/monthly_times_screen.dart';
import 'package:myt_flutter/features/prayer/screens/prayer_home_screen.dart';
import 'package:myt_flutter/features/prayer/widgets/reminders_sheet.dart';
import 'package:myt_flutter/features/profile/screens/burial_services_screen.dart';
import 'package:myt_flutter/features/profile/screens/confirm_email_screen.dart';
import 'package:myt_flutter/features/profile/screens/reset_password_screen.dart';
import 'package:myt_flutter/features/profile/screens/delete_account_screen.dart';
import 'package:myt_flutter/features/profile/screens/mosque_info_screen.dart';
import 'package:myt_flutter/features/profile/screens/profile_root_screen.dart';
import 'package:myt_flutter/features/profile/screens/settings_screen.dart';
import 'package:myt_flutter/features/profile/screens/sign_in_screen.dart';
import 'package:myt_flutter/features/profile/screens/sign_up_screen.dart';
import 'package:myt_flutter/features/profile/widgets/about_sheet.dart';
import 'package:myt_flutter/features/profile/widgets/add_name_sheet.dart';
import 'package:myt_flutter/features/profile/widgets/appearance_sheet.dart';
import 'package:myt_flutter/features/profile/widgets/language_sheet.dart';
import 'package:myt_flutter/features/push/push_prompt_sheet.dart';
import 'package:myt_flutter/features/registration/registration_screen.dart';
import 'package:myt_flutter/features/update/screens/update_required_screen.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/auth_provider.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/shared/providers/donations_provider.dart';
import 'package:myt_flutter/shared/providers/events_news_provider.dart';
import 'package:myt_flutter/shared/providers/prayer_provider.dart';
import 'package:myt_flutter/shared/providers/push_provider.dart';
import 'package:myt_flutter/shared/providers/registration_provider.dart';
import 'package:myt_flutter/shared/providers/reminders_provider.dart';
import 'package:myt_flutter/theme/app_icon.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/island_tab_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../prayer/hero_identity_row_test.dart' show loadManrope;
import '../push/fakes.dart';
import '../registration/harness.dart' as reg;

/// Every main screen and sheet in French on a 390 pt phone, in the bundled
/// Manrope (wider than the SF Pro the phone draws, so a fit here is a fit
/// there). Fails on a RenderFlex overflow or on text cut by its widget.
///
/// With SHOT_DIR set, each screen is also written there as a PNG:
/// `SHOT_DIR=/some/dir flutter test test/l10n/french_layout_test.dart`
void main() {
  late ContentBundle content;
  final shotDir = Platform.environment['SHOT_DIR'];

  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting();
    initMosqueTime();
    content = ContentBundle.parse(
      jsonDecode(File(ContentRepository.defaultsAsset).readAsStringSync()),
      fallback: ContentBundle.empty,
      source: ContentSource.defaults,
    );
  });

  final payload = PrayerCachePayload.fromJson({
    'dailyPrayerTimes': [
      {'name': 'Fajr', 'time': '05:43', 'iqamah': '06:13'},
      {'name': 'Sunrise', 'time': '07:11'},
      {'name': 'Dhuhr', 'time': '1:11', 'iqamah': '1:30'},
      {'name': 'Asr', 'time': '4:23', 'iqamah': '4:40'},
      {'name': 'Maghrib', 'time': '7:02', 'iqamah': '7:07'},
      {'name': 'Isha', 'time': '8:19', 'iqamah': '8:35'},
    ],
    'hijriDate': '22.3.1448',
    'gregorianDate': '02.11.2026',
    'jumaaPrayerTime': '1:30',
  });

  final now = DateTime.now();
  UpcomingEvent event(String id, String recurrence, {String? after, bool form = false, bool contribution = false}) {
    final start = tz.TZDateTime.from(now.add(const Duration(days: 9)), mosqueTz);
    return UpcomingEvent(
      YouthEvent(
        id: id,
        title: 'Rencontre des jeunes',
        description: 'Une soirée de discussion, suivie d\'un repas.',
        location: '336 Pape Avenue, Toronto',
        dateTime: start.toUtc(),
        isFree: true,
        attendingCount: 0,
        category: 'youth',
        recurrence: recurrence,
        isPublished: true,
        startsAfterPrayer: after,
        registrationForm: form ? reg.form() : null,
        contributionPhone: contribution ? '416 555 0142' : null,
        contributionHeading: contribution ? 'Souhaitez-vous contribuer à cette soirée?' : null,
        contributionText: contribution ? 'Pour apporter un repas ou une collation, vous pouvez nous appeler.' : null,
      ),
      start,
    );
  }

  final announcement = Announcement(
    id: 'a1',
    title: 'Horaires du bureau',
    description: 'Le bureau sera fermé lundi prochain.',
    createdAt: now.subtract(const Duration(days: 2)),
  );
  final user = User(
    id: 'u1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2024-03-01T00:00:00Z',
    email: 'prenom.nom.long@exemple.com',
  );
  final profile = <String, dynamic>{
    'full_name': 'Zeynep Aksoy',
    'email': 'prenom.nom.long@exemple.com',
    'notifications_enabled': true,
    'created_at': '2024-03-01T00:00:00Z',
    'phone': '+14165550123',
    'date_of_birth': '1990-05-04',
  };
  final application = MarriageApplication(
    filePath: 'u1/x.pdf',
    kind: DocumentKind.pdf,
    sizeBytes: 1800000,
    createdAt: DateTime(2026, 10, 3),
  );

  /// Lays [home] out, collects what doesn't fit.
  Future<void> check(
    WidgetTester tester,
    String name,
    Widget Function(BuildContext) home, {
    Object? registration,
    bool signedIn = true,
    bool needsDob = false,
    Future<void> Function(WidgetTester, BuildContext)? open,
    PushPermission permission = PushPermission.authorized,
    double height = 1800,
    Future<void> Function(WidgetTester)? after,
    Locale locale = const Locale('fr'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = Size(390 * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final problems = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        problems.add(text.split('\n').first);
      } else {
        previous?.call(details);
      }
    };

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, _) => Material(child: home(context))),
        GoRoute(path: '/prayer/monthly', builder: (_, _) => const MonthlyTimesScreen()),
      ],
    );
    final api = reg.FakeRegistrationApi([
      registration ?? reg.stateJson(placesLeft: 3, deadline: '2026-12-15T23:59:00Z'),
    ]);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ProviderScope(
          overrides: [
            initialContentProvider.overrideWithValue(content),
            appVersionProvider.overrideWithValue('1.3.1'),
            currentUserProvider.overrideWithValue(signedIn ? user : null),
            userProfileProvider.overrideWith(
              (ref) async => needsDob
                  ? {...profile, 'date_of_birth': null}
                  : profile,
            ),
            myApplicationProvider.overrideWith((ref) async => application),
            prayerProvider.overrideWith((ref) async => payload),
            prayerMonthProvider.overrideWith((ref) async {
              final today = mosqueNow();
              return [
                for (var i = 0; i < 31; i++)
                  if (i != 3)
                    () {
                      final day = DateTime(today.year, today.month, today.day + i);
                      return (
                        date: mosqueDateKey(day),
                        payload: PrayerCachePayload(
                          dailyPrayerTimes: payload.dailyPrayerTimes,
                          hijriDate: '26.5.1448',
                          gregorianDate: diyanetDate(day),
                          jumaaPrayerTime: '1:30',
                        ),
                      );
                    }(),
              ];
            }),
            eventsProvider.overrideWith(
              (ref) async => [
                event('e1', 'none', form: true),
                event('e2', 'weekly', after: 'maghrib'),
                event('e3', 'biweekly'),
                event('e4', 'monthly'),
              ],
            ),
            newsProvider.overrideWith((ref) async => [announcement]),
            initialDonationFundsProvider.overrideWithValue(const []),
            athanBundledProvider.overrideWith((ref) async => true),
            reminderSettingsProvider.overrideWith(_Settings.new),
            registrationApiProvider.overrideWithValue(api),
            deviceCredentialsProvider.overrideWithValue(() async => reg.device),
            initialPushPermissionProvider.overrideWithValue(permission),
            initialPushLocalProvider.overrideWithValue(const PushLocal(saved: true)),
            pushApiProvider.overrideWithValue(FakePushApi()
              ..settings = const DeviceSettings(
                events: true,
                announcements: true,
                deviceCode: 'ABCD2345',
                mutedEventIds: {},
              )),
            identityStoreProvider.overrideWithValue(MemoryIdentityStore()),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: appLightTheme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    if (open != null) {
      final context = tester.element(find.byType(Scaffold).first);
      await open(tester, context);
      await tester.pump(const Duration(milliseconds: 400));
    }
    if (after != null) await after(tester);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Text cut by its widget.
    void visit(RenderObject object) {
      if (object is RenderParagraph) {
        final wanted = object.getMaxIntrinsicWidth(double.infinity);
        final oneLine = object.maxLines == 1 || !object.softWrap;
        if (object.didExceedMaxLines ||
            (oneLine && wanted > object.size.width + 0.5)) {
          problems.add('cut: "${object.text.toPlainText()}"');
        }
        // French clock times read "16 h 55", never "4:55 PM" or "16:55". The
        // countdown's "0:17:58" isn't a clock time.
        if (locale.languageCode == 'fr' &&
            RegExp(r'(?<![:\d])\d{1,2}:\d{2}(?![:\d])|\b[AP]M\b').hasMatch(object.text.toPlainText())) {
          problems.add('clock: "${object.text.toPlainText()}"');
        }
      }
      object.visitChildren(visit);
    }

    visit(tester.renderObject(find.byKey(boundary)));

    if (shotDir != null) {
      final image = await tester.runAsync(() async {
        final render = tester.renderObject(find.byKey(boundary)) as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return bytes!.buffer.asUint8List();
      });
      File('$shotDir/$name.png').writeAsBytesSync(image!);
    }
    await tester.pumpWidget(const SizedBox());
    FlutterError.onError = previous;
    expect(problems, isEmpty, reason: name);
  }

  final screens = <String, Widget Function(BuildContext)>{
    'prayer_home': (_) => const PrayerHomeScreen(),
    'monthly_times': (_) => const MonthlyTimesScreen(),
    'community_events': (_) => const CommunityScreen(),
    'event_recurring': (_) => EventDetailScreen(upcoming: event('e2', 'weekly', after: 'maghrib')),
    'event_contribution': (_) => EventDetailScreen(upcoming: event('e5', 'none', contribution: true)),
    'announcement': (_) => AnnouncementDetailScreen(item: announcement),
    'profile_signed_in': (_) => const ProfileRootScreen(),
    'settings': (_) => const SettingsScreen(),
    'sign_in': (_) => const SignInScreen(),
    'sign_up': (_) => const SignUpScreen(),
    'confirm_email': (_) => const ConfirmEmailScreen(email: 'ayse.yilmaz@example.com'),
    'reset_email': (_) => const ResetPasswordScreen(email: 'ayse.yilmaz@example.com'),
    'reset_code': (_) => const ResetPasswordScreen(
          email: 'ayse.yilmaz@example.com',
          initialStep: ResetStep.code,
        ),
    'reset_password': (_) => const ResetPasswordScreen(initialStep: ResetStep.password),
    'delete_account': (_) => const DeleteAccountScreen(),
    'mosque_info': (_) => const MosqueInfoScreen(),
    'burial': (_) => const BurialServicesScreen(),
    'update_required': (_) => const UpdateRequiredScreen(),
    'marriage_upload': (_) => const MarriageUploadScreen(),
    'marriage_received': (_) => const MarriageReceivedScreen(),
    'marriage_status': (_) => const MarriageStatusScreen(),
    'registration_form': (_) => RegistrationScreen(upcoming: event('e1', 'none', form: true)),
  };

  for (final MapEntry(:key, :value) in screens.entries) {
    testWidgets('$key fits', (tester) => check(tester, key, value));
  }

  // The email code screens, in every language at iPhone size (1.4.1).
  for (final lang in const ['tr', 'en']) {
    for (final name in const [
      'sign_in',
      'confirm_email',
      'reset_email',
      'reset_code',
      'reset_password',
    ]) {
      testWidgets('$name fits ($lang)', (tester) => check(
            tester,
            '${name}_$lang',
            screens[name]!,
            signedIn: false,
            height: 852,
            locale: Locale(lang),
          ));
    }
  }

  testWidgets('the no-cancel note fits on top of the registration form', (tester) {
    return check(
      tester,
      'registration_note',
      (_) => RegistrationScreen(upcoming: event('e1', 'none', form: true)),
      after: (tester) async {
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            "Une inscription ne peut pas être annulée dans l'application. "
            'Pour la modifier, veuillez communiquer avec la mosquée.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('prayer times on the home screen read the French way', (tester) {
    return check(
      tester,
      'home_clock',
      (_) => const PrayerHomeScreen(),
      after: (tester) async {
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining(RegExp(r'^\d{1,2}\u00A0h(\u00A0\d{2})?$')), findsWidgets);
      },
    );
  });

  // The monthly table and the reminders are their own untitled card under
  // today's times, not rows of it (1.4.0).
  for (final (lang, monthly, reminders) in const [
    ('fr', 'Horaires du mois', 'Notifications de prière'),
    ('tr', 'Aylık vakitler', 'Namaz bildirimleri'),
    ('en', 'Monthly times', 'Prayer notifications'),
  ]) {
    testWidgets('prayer home: the links card under the times ($lang)', (tester) {
      return check(
        tester,
        'prayer_links_$lang',
        (_) => const PrayerHomeScreen(),
        locale: Locale(lang),
        height: 852,
        after: (tester) async {
          final links = find.byKey(const ValueKey('prayer-links'));
          await tester.scrollUntilVisible(links, 300, scrollable: find.byType(Scrollable).first);
          // The times card above, the links card near the bottom: the shot.
          await tester.runAsync(
            () => Scrollable.ensureVisible(tester.element(links), alignment: 0.85),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.descendant(of: links, matching: find.text(monthly)), findsOneWidget);
          expect(find.descendant(of: links, matching: find.text(reminders)), findsOneWidget);
          expect(find.text(monthly), findsOneWidget, reason: 'not in the times card too');
          expect(find.text(reminders), findsOneWidget);

          // Below the times card: the Isha row is above it.
          final isha = find.text(lang == 'tr' ? 'Yatsı' : lang == 'fr' ? 'Icha' : 'Isha');
          expect(tester.getTopLeft(links).dy, greaterThan(tester.getBottomLeft(isha.first).dy));
          expect(find.ancestor(of: isha.first, matching: links), findsNothing);
        },
      );
    });
  }

  testWidgets('the monthly row opens the monthly screen', (tester) {
    return check(
      tester,
      'prayer_links_open',
      (_) => const PrayerHomeScreen(),
      after: (tester) async {
        final row = find.text('Horaires du mois');
        await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
        await tester.tap(row);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byType(MonthlyTimesScreen), findsOneWidget);
      },
    );
  });

  testWidgets('profile signed out fits', (tester) {
    return check(tester, 'profile_signed_out', (_) => const ProfileRootScreen(), signedIn: false);
  });
  testWidgets('marriage gate fits', (tester) {
    return check(tester, 'marriage_gate', (_) => const MarriageGateScreen(), signedIn: false);
  });
  testWidgets('date of birth step fits', (tester) {
    return check(tester, 'marriage_dob', (_) => const MarriageUploadScreen(), needsDob: true);
  });
  testWidgets('announcements segment fits', (tester) {
    return check(
      tester,
      'community_announcements',
      (_) => const CommunityScreen(),
      after: (tester) async {
        await tester.tap(find.text('Annonces').first);
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
  });

  // The event page in the registration states that have the longest texts.
  final states = <String, Object>{
    'open': reg.stateJson(placesLeft: 3, deadline: '2026-12-15T23:59:00Z'),
    'registered': reg.stateJson(
      status: 'registered',
      me: reg.member(registration: {
        'created_at': '2026-10-03T14:00:00Z',
        'full_name': 'Zeynep Aksoy',
        'phone': '+14165550123',
        'answers': {'q_SHRT2222': 'Danforth CI'},
      }),
    ),
    'deadline': reg.stateJson(status: 'deadline_passed', deadline: '2026-10-15T23:59:00Z'),
    'full': reg.stateJson(status: 'full'),
    'closed': reg.stateJson(status: 'closed'),
  };
  for (final MapEntry(:key, :value) in states.entries) {
    testWidgets('event page ($key) fits', (tester) {
      return check(
        tester,
        'event_$key',
        (_) => EventDetailScreen(upcoming: event('e1', 'none', form: true)),
        registration: value,
      );
    });
  }

  final sheets = <String, Future<Object?> Function(BuildContext)>{
    'sheet_reminders': showRemindersSheet,
    'sheet_donate': showDonateSheet,
    'sheet_language': showLanguageSheet,
    'sheet_appearance': showAppearanceSheet,
    'sheet_about': showAboutSheet,
    'sheet_add_name': showAddNameSheet,
    'sheet_withdraw': showWithdrawSheet,
  };
  for (final MapEntry(:key, :value) in sheets.entries) {
    testWidgets('$key fits', (tester) {
      return check(
        tester,
        key,
        (_) => const Scaffold(body: SizedBox.expand()),
        height: 900,
        open: (tester, context) async {
          value(context);
        },
      );
    });
  }

  testWidgets('tab bar fits', (tester) {
    return check(
      tester,
      'tab_bar',
      (context) => Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: IslandTabBar(
            tabs: [
              IslandTab(icon: AppIcons.mosque, label: context.l10n.tabPrayer),
              IslandTab(icon: AppIcons.calendar, label: context.l10n.tabCommunity),
              IslandTab(icon: AppIcons.person, label: context.l10n.tabProfile),
            ],
            index: 1,
            onSelect: (_) {},
          ),
        ),
      ),
      height: 300,
    );
  });

  testWidgets('push pre-prompt fits', (tester) {
    return check(
      tester,
      'sheet_push_prompt',
      (_) => const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: PushPromptSheet())),
      height: 900,
    );
  });
}

class _Settings extends ReminderSettingsNotifier {
  @override
  Future<ReminderSettings> build() async => const ReminderSettings();
}
