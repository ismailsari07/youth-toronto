import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:myt_flutter/core/forms_v2/marriage_form.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/features/marriage/data/marriage_v2_service.dart';
import 'package:myt_flutter/features/marriage/screens/marriage_form_screen.dart';
import 'package:myt_flutter/features/registration/question_fields.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/app_card.dart';
import 'package:myt_flutter/ui/components/app_text_input.dart';

/// The seed form (published v1), as the app receives it.
final PublishedMarriageForm seed = () {
  final raw = jsonDecode(File('test/fixtures/marriage-form-v1.json').readAsStringSync()) as Map<String, dynamic>;
  return PublishedMarriageForm(raw['version'] as int, (raw['schema'] as Map).cast<String, dynamic>());
}();

Map fieldById(String id) => allFields(seed.schema).firstWhere((f) => f['id'] == id);
String trLabel(String id) => (fieldById(id)['label'] as Map)['tr'] as String;
String trOption(String id, String option) =>
    ((fieldById(id)['options'] as List).firstWhere((o) => (o as Map)['id'] == option) as Map)['label']['tr'] as String;
String firstOption(String id) => ((fieldById(id)['options'] as List).first as Map)['id'] as String;

/// One submission the fake sender received.
class Sent {
  Sent(this.answers, this.photos, this.locale, this.appVersion);
  final Map<String, Object> answers;
  final List<NumberedPhoto> photos;
  final String locale;
  final String? appVersion;
}

Uint8List jpeg() => img.encodeJpg(img.Image(width: 30, height: 40)..clear(img.ColorRgb8(10, 120, 60)));

Future<AppLocalizations> pumpForm(
  WidgetTester tester, {
  required List<Sent> sent,
  Object? failWith,
  Map<String, dynamic>? profile,
  String accountEmail = 'ayse@example.com',
  Locale locale = const Locale('tr'),
}) async {
  initMosqueTime();
  // Tall enough that every field is built (the list is lazy).
  tester.view.physicalSize = const Size(430, 14000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Future<void> submit({
    required PublishedMarriageForm form,
    required Map<String, Object> answers,
    required List<NumberedPhoto> photos,
    required String locale,
    String? appVersion,
    void Function(int done, int total)? onProgress,
  }) async {
    if (failWith != null) throw failWith;
    sent.add(Sent(answers, photos, locale, appVersion));
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(onPressed: () => context.push('/form'), child: const Text('OPEN')),
          ),
        ),
      ),
      GoRoute(
        path: '/form',
        builder: (_, _) => MarriageFormBody(
          form: seed,
          profile: profile ?? {'date_of_birth': '1995-03-14', 'phone': '+14165550123'},
          accountEmail: accountEmail,
          pickPhoto: () async => jpeg(),
          submit: submit,
        ),
      ),
      GoRoute(path: '/profile/marriage/submitted', builder: (_, _) => const Scaffold(body: Text('SUBMITTED'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appVersionProvider.overrideWithValue('1.5.0')],
      child: MaterialApp.router(
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
        builder: (_, child) => KeyboardAccessoryHost(child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
  return lookupAppLocalizations(locale);
}

/// A field's label (required ones are rich text with an asterisk).
Finder label(String text) => find.byWidgetPredicate((w) => w is FieldLabel && w.text == text);

/// The card that holds the field labelled [text].
Finder card(String text) => find.ancestor(of: label(text), matching: find.byType(AppCard)).first;

Future<void> type(WidgetTester tester, String fieldId, String text) async {
  await tester.enterText(find.descendant(of: card(trLabel(fieldId)), matching: find.byType(EditableText)), text);
  await tester.pump();
}

Future<void> choose(WidgetTester tester, String fieldId, String optionId) async {
  await tester.tap(find.descendant(of: card(trLabel(fieldId)), matching: find.text(trOption(fieldId, optionId))));
  await tester.pump();
}

// Seed v1 ids (pape-admin 20261104120100).
const name = 'q_6MNWUCPS', gender = 'q_AC9NYP69', dob = 'q_VRN8RTR6', marital = 'q_CKNYBMR7';
const hometown = 'q_U8NJG9Q3', parentsHere = 'q_ATD4MAR3', parentName = 'q_9WT63WUQ';
const sector = 'q_9WLVXQQN', position = 'q_D9DX93NA', prayer = 'q_JBRTVSZE', smoke = 'q_WLC54CHY', alcohol = 'q_8MUN4WD3';
const about = 'q_YTDVN95J', looking = 'q_L466YF2L', phone = 'q_QC64L9RR', email = 'q_B5T8EW63';
const photos = 'q_X3ZG8GU3', consent = 'q_U3DRC4Q2';

Future<void> fillRequired(WidgetTester tester) async {
  await type(tester, name, '  Ayşe Yılmaz ');
  await choose(tester, gender, firstOption(gender));
  await choose(tester, marital, firstOption(marital));
  await type(tester, hometown, 'Trabzon');
  await choose(tester, parentsHere, firstOption(parentsHere));
  await type(tester, sector, 'Sağlık');
  await type(tester, position, 'Hemşire');
  await choose(tester, prayer, firstOption(prayer));
  await choose(tester, smoke, firstOption(smoke));
  await choose(tester, alcohol, firstOption(alcohol));
  await type(tester, about, 'Kısa bir tanıtım.');
  await type(tester, looking, 'Dürüst biri.');
  await tester.tap(find.text(trLabel(consent)));
  await tester.pump();
}

Future<void> addPhoto(WidgetTester tester, AppLocalizations l) async {
  await tester.runAsync(() async {
    await tester.tap(find.text(l.mfAddPhoto));
    // preparePhoto runs in an isolate.
    for (var i = 0; i < 50 && find.text(l.mfAddPhoto).evaluate().isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every section and visible field of the seed form renders', (tester) async {
    await pumpForm(tester, sent: []);
    for (final s in (seed.schema['sections'] as List).cast<Map>()) {
      expect(find.text((s['title'] as Map)['tr'] as String), findsOneWidget);
    }
    for (final id in [name, gender, marital, hometown, sector, about, phone, email, photos]) {
      expect(label(trLabel(id)), findsOneWidget, reason: id);
    }
    expect(find.text(trLabel(consent)), findsOneWidget);
  });

  testWidgets('show_if: the parent fields appear only for the matching answers', (tester) async {
    await pumpForm(tester, sent: []);
    expect(label(trLabel(parentName)), findsNothing);
    final anyOf = ((fieldById(parentName)['show_if'] as Map)['any_of'] as List).cast<String>();
    await choose(tester, parentsHere, anyOf.first);
    expect(label(trLabel(parentName)), findsOneWidget);
    final other = ((fieldById(parentsHere)['options'] as List).cast<Map>())
        .map((o) => o['id'] as String)
        .firstWhere((id) => !anyOf.contains(id));
    await choose(tester, parentsHere, other);
    expect(label(trLabel(parentName)), findsNothing);
  });

  testWidgets('birth date, phone and email come from the profile and the account', (tester) async {
    final l = await pumpForm(tester, sent: []);
    expect(find.textContaining('14 Mart 1995'), findsOneWidget);
    expect(find.textContaining(l.mfAge(ageOn('1995-03-14', isoDateNow()))), findsOneWidget);
    expect(find.text(l.mfFromProfile), findsOneWidget);
    expect(find.descendant(of: card(trLabel(phone)), matching: find.text('+14165550123')), findsOneWidget);
    expect(find.descendant(of: card(trLabel(email)), matching: find.text('ayse@example.com')), findsOneWidget);
  });

  testWidgets('an Apple relay address is not prefilled', (tester) async {
    await pumpForm(tester, sent: [], accountEmail: 'x1@privaterelay.appleid.com');
    expect(find.text('x1@privaterelay.appleid.com'), findsNothing);
  });

  testWidgets('sending an empty form shows the errors and sends nothing', (tester) async {
    final sent = <Sent>[];
    final l = await pumpForm(tester, sent: sent);
    await tester.tap(find.text(l.mfSend));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.text(l.mfFixErrors), findsOneWidget);
    expect(find.text(l.regErrRequired), findsWidgets);
    expect(find.text(l.mfErrPhotos), findsOneWidget);
    expect(find.text(l.mfErrConsent), findsOneWidget);
  });

  testWidgets('a filled form with a photo is sent with the clean answers', (tester) async {
    final sent = <Sent>[];
    final l = await pumpForm(tester, sent: sent);
    await fillRequired(tester);
    await addPhoto(tester, l);
    expect(find.byType(Image), findsOneWidget, reason: 'the thumbnail');
    await tester.tap(find.text(l.mfSend));
    await tester.pumpAndSettle();

    expect(find.text('SUBMITTED'), findsOneWidget);
    expect(sent, hasLength(1));
    final a = sent.single.answers;
    expect(a[name], 'Ayşe Yılmaz', reason: 'trimmed');
    expect(a[dob], '1995-03-14');
    expect(a[phone], '+14165550123');
    expect(a[email], 'ayse@example.com');
    expect(a[photos], [1]);
    expect(a[consent], true);
    expect(a.containsKey(parentName), isFalse, reason: 'hidden and unanswered');
    expect(sent.single.photos.single.n, 1);
    expect((sent.single.photos.single.photo.width, sent.single.photos.single.photo.height), (30, 40));
    expect(sent.single.locale, 'tr');
    expect(sent.single.appVersion, '1.5.0');
    // The answers pass the same check the key holder's browser runs.
    expect(validateAnswers(seed.schema, a, isoDateNow()).errors, isEmpty);
  });

  testWidgets('a hidden field\'s answer is dropped', (tester) async {
    final sent = <Sent>[];
    final l = await pumpForm(tester, sent: sent);
    await fillRequired(tester);
    final anyOf = ((fieldById(parentName)['show_if'] as Map)['any_of'] as List).cast<String>();
    await choose(tester, parentsHere, anyOf.first);
    await type(tester, parentName, 'Mehmet');
    final other = ((fieldById(parentsHere)['options'] as List).cast<Map>())
        .map((o) => o['id'] as String)
        .firstWhere((id) => !anyOf.contains(id));
    await choose(tester, parentsHere, other);
    await addPhoto(tester, l);
    await tester.tap(find.text(l.mfSend));
    await tester.pumpAndSettle();
    expect(sent.single.answers.containsKey(parentName), isFalse);
  });

  testWidgets('a failed send keeps the form and says so', (tester) async {
    final sent = <Sent>[];
    final l = await pumpForm(tester, sent: sent, failWith: const SubmitException(SubmitFailure.sendFailed));
    await fillRequired(tester);
    await addPhoto(tester, l);
    await tester.tap(find.text(l.mfSend));
    await tester.pumpAndSettle();
    expect(find.text(l.mfErrSend), findsOneWidget);
    expect(find.text('SUBMITTED'), findsNothing);
    expect(find.descendant(of: card(trLabel(name)), matching: find.text('  Ayşe Yılmaz ')), findsOneWidget);
  });

  testWidgets('leaving a started form asks first (answers are memory only)', (tester) async {
    final l = await pumpForm(tester, sent: []);
    await type(tester, hometown, 'Rize');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l.mfLeaveTitle), findsOneWidget);
    await tester.tap(find.text(l.mfStay));
    await tester.pumpAndSettle();
    expect(label(trLabel(hometown)), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.mfLeave));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('an untouched form closes without asking', (tester) async {
    final l = await pumpForm(tester, sent: []);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l.mfLeaveTitle), findsNothing);
    expect(find.text('OPEN'), findsOneWidget);
  });
}

String isoDateNow() {
  final t = mosqueNow();
  return '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
