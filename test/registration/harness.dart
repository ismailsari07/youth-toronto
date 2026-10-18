import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myt_flutter/core/event_schedule.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/push/push_prompt.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:myt_flutter/core/registration/registration_api.dart';
import 'package:myt_flutter/core/registration/registration_state.dart';
import 'package:myt_flutter/features/registration/registration_screen.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/auth_provider.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/shared/providers/push_provider.dart';
import 'package:myt_flutter/shared/providers/registration_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_text_input.dart';
import 'package:timezone/timezone.dart' as tz;

import '../push/fakes.dart';

const eventId = '9b1d6a0e-0000-4000-8000-000000000001';
const device = (installId: 'install-1', secret: 'secret-1');

/// The form used across these tests: all eight types.
Map<String, Object> form() => {
      'questions': [
        {'id': 'q_SHRT2222', 'type': 'short_text', 'required': true, 'label': {'tr': 'Okul', 'en': 'School'}},
        {
          'id': 'q_NMBR2222', 'type': 'number', 'required': false, 'min': 12, 'max': 18, 'integer': true,
          'label': {'tr': 'Yaş', 'en': 'Age'},
        },
        {
          'id': 'q_SNGL2222', 'type': 'single_choice', 'required': false, 'label': {'tr': 'Beden', 'en': 'Size'},
          'options': [
            {'id': 'o_AAAAA2', 'label': {'tr': 'S'}},
            {'id': 'o_AAAAA3', 'label': {'tr': 'M'}},
          ],
        },
        {
          'id': 'q_MLTP2222', 'type': 'multiple_choice', 'required': false, 'label': {'tr': 'Atölye', 'en': 'Workshops'},
          'options': [
            {'id': 'o_BBBBB2', 'label': {'tr': 'Hat', 'en': 'Calligraphy'}},
            {'id': 'o_BBBBB3', 'label': {'tr': 'Spor', 'en': 'Sports'}},
          ],
        },
        {'id': 'q_YSN22222', 'type': 'yes_no', 'required': true, 'label': {'tr': 'Servis?', 'en': 'Shuttle?'}},
        {'id': 'q_DATE2222', 'type': 'date', 'required': false, 'label': {'tr': 'Doğum', 'en': 'Born'}},
        {'id': 'q_PHNE2222', 'type': 'phone', 'required': false, 'label': {'tr': 'Veli', 'en': 'Parent'}},
        {'id': 'q_LNGT2222', 'type': 'long_text', 'required': false, 'label': {'tr': 'Not', 'en': 'Note'}},
      ],
    };

Map<String, Object?> member({
  bool nameMissing = false,
  String email = 'zeynep@example.com',
  bool phoneMissing = true,
  Map<String, Object?>? registration,
}) =>
    {
      'has_profile': true,
      'full_name': nameMissing ? '' : 'Zeynep Aksoy',
      'name_missing': nameMissing,
      'email': email,
      'phone': phoneMissing ? null : '+14165550123',
      'phone_missing': phoneMissing,
      'registration': registration,
    };

Map<String, Object?> stateJson({
  String status = 'open',
  Object? me,
  int? placesLeft,
  bool requirePhone = false,
  bool available = true,
  String? deadline,
  Map<String, Object>? formJson,
}) =>
    {
      'form': formJson ?? form(),
      'form_version': 'v1',
      'status': status,
      'deadline': deadline,
      'places_left': placesLeft,
      'require_phone': requirePhone,
      'available': available,
      'me': me,
    };

/// Scripted answers; records every call.
class FakeRegistrationApi implements RegistrationApi {
  FakeRegistrationApi(this.states);

  /// Answers to state(), in order; the last one repeats. An Exception is
  /// thrown instead of returned.
  final List<Object> states;
  int stateCalls = 0;
  final viewCalls = <(String, DeviceCredentials)>[];
  int? views = 30;

  final registerCalls = <Map<String, Object?>>[];

  /// Errors for register(), in order; then success.
  final registerErrors = <Object>[];

  @override
  Future<RegistrationState> state(String eventId) async {
    final next = states[stateCalls < states.length ? stateCalls : states.length - 1];
    stateCalls++;
    if (next is Exception) throw next;
    return RegistrationState.fromJson(next as Map<String, dynamic>);
  }

  @override
  Future<int?> recordView(String eventId, DeviceCredentials device) async {
    viewCalls.add((eventId, device));
    return views;
  }

  @override
  Future<void> register({
    required String eventId,
    required String formVersion,
    required Map<String, Object> answers,
    String? fullName,
    String? phone,
    DeviceCredentials? device,
  }) async {
    registerCalls.add({
      'event': eventId,
      'version': formVersion,
      'answers': answers,
      'name': fullName,
      'phone': phone,
      'device': device,
    });
    if (registerErrors.isNotEmpty) throw registerErrors.removeAt(0);
  }
}

UpcomingEvent upcomingEvent({String recurrence = 'none', bool withForm = true}) {
  initMosqueTime();
  return UpcomingEvent(
    YouthEvent(
      id: eventId,
      title: 'Youth Camp',
      dateTime: DateTime.utc(2026, 11, 8, 14),
      isFree: true,
      attendingCount: 0,
      category: 'youth',
      recurrence: recurrence,
      isPublished: true,
      registrationForm: withForm ? form() : null,
    ),
    tz.TZDateTime(mosqueTz, 2026, 11, 8, 9),
  );
}

/// [home] at '/', with stand-ins for sign-in and the real form route.
Future<GoRouter> pumpRegistration(
  WidgetTester tester,
  FakeRegistrationApi api, {
  required Widget Function(BuildContext) home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  PushLocal pushLocal = const PushLocal(saved: true),
  PushPermission permission = PushPermission.authorized,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, _) => home(context)),
      GoRoute(
        path: '/profile/sign-in',
        builder: (_, _) => const Scaffold(body: Text('SIGN IN SCREEN')),
      ),
      GoRoute(
        path: '/community/event/register',
        builder: (_, state) => RegistrationScreen(upcoming: state.extra! as UpcomingEvent),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        registrationApiProvider.overrideWithValue(api),
        deviceCredentialsProvider.overrideWithValue(() async => device),
        currentUserProvider.overrideWithValue(null),
        initialPushPermissionProvider.overrideWithValue(permission),
        initialPushLocalProvider.overrideWithValue(pushLocal),
        appVersionProvider.overrideWithValue('1.2.0'),
        pushApiProvider.overrideWithValue(FakePushApi()),
        identityStoreProvider.overrideWithValue(MemoryIdentityStore()),
      ],
      child: MaterialApp.router(
        theme: theme ?? appLightTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (_, child) => KeyboardAccessoryHost(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
