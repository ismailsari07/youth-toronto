import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myt_flutter/core/auth_service.dart';
import 'package:myt_flutter/core/email_auth.dart';
import 'package:myt_flutter/features/profile/screens/confirm_email_screen.dart';
import 'package:myt_flutter/features/profile/screens/reset_password_screen.dart';
import 'package:myt_flutter/features/profile/screens/sign_in_screen.dart';
import 'package:myt_flutter/features/profile/screens/sign_up_screen.dart';
import 'package:myt_flutter/features/profile/widgets/email_code.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/providers/auth_provider.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthError err(AuthFailure kind) => (kind: kind, serverMessage: null);

class FakeEmailAuth implements EmailAuth {
  final calls = <String>[];
  AuthError? signInError;
  ({SignUpResult? result, AuthError? error}) signUpOutcome =
      (result: SignUpResult.confirmEmail, error: null);
  AuthError? verifyError;
  AuthError? resetError;

  @override
  Future<AuthError?> signIn(String email, String password) async {
    calls.add('signIn $email');
    return signInError;
  }

  @override
  Future<({SignUpResult? result, AuthError? error})> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    calls.add('signUp $email');
    return signUpOutcome;
  }

  @override
  Future<AuthError?> verifySignUp(String email, String code) async {
    calls.add('verifySignUp $email $code');
    return verifyError;
  }

  @override
  Future<AuthError?> resendSignUp(String email) async {
    calls.add('resendSignUp $email');
    return null;
  }

  @override
  Future<AuthError?> requestPasswordReset(String email) async {
    calls.add('reset $email');
    return resetError;
  }

  @override
  Future<AuthError?> verifyRecovery(String email, String code) async {
    calls.add('verifyRecovery $email $code');
    return verifyError;
  }

  @override
  Future<AuthError?> setNewPassword(String password) async {
    calls.add('setNewPassword');
    return null;
  }
}

void main() {
  group('Supabase answers', () {
    User user(List<UserIdentity>? identities) => User(
          id: 'u1',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-11-06T00:00:00Z',
          identities: identities,
        );
    final identity = UserIdentity(
      id: 'u1',
      userId: 'u1',
      identityData: const {},
      identityId: 'i1',
      provider: 'email',
      createdAt: null,
      lastSignInAt: null,
      updatedAt: null,
    );
    final session = Session(
      accessToken: 'a',
      tokenType: 'bearer',
      user: user([identity]),
    );

    test('a session means confirmation is off: signed in', () {
      expect(
        signUpResultOf(AuthResponse(session: session, user: session.user)),
        SignUpResult.signedIn,
      );
    });

    test('no session: a code was sent', () {
      expect(
        signUpResultOf(AuthResponse(user: user([identity]))),
        SignUpResult.confirmEmail,
      );
    });

    test('no identities: the address already has an account', () {
      expect(
        signUpResultOf(AuthResponse(user: user(const []))),
        SignUpResult.alreadyRegistered,
      );
    });

    test('error codes of the code and password steps', () {
      AuthFailure kind(String code) =>
          AuthService.errorFrom(AuthException('x', code: code)).kind;
      expect(kind('otp_expired'), AuthFailure.invalidCode);
      expect(kind('same_password'), AuthFailure.samePassword);
      expect(kind('email_not_confirmed'), AuthFailure.emailNotConfirmed);
      expect(kind('over_email_send_rate_limit'), AuthFailure.rateLimited);
    });

    test('a reset request never tells whether the address has an account', () {
      expect(resetRequestError(null), isNull);
      expect(resetRequestError(err(AuthFailure.unexpected)), isNull);
      expect(resetRequestError(err(AuthFailure.invalidCredentials)), isNull);
      expect(resetRequestError(err(AuthFailure.rateLimited))?.kind, AuthFailure.rateLimited);
      expect(resetRequestError(err(AuthFailure.network))?.kind, AuthFailure.network);
    });

    test('codes are exactly six digits', () {
      expect(isCompleteCode('123456'), isTrue);
      expect(isCompleteCode('12345'), isFalse);
      expect(isCompleteCode('1234567'), isFalse);
      expect(isCompleteCode('12a456'), isFalse);
    });

    test('every email request carries the app redirect the templates test for', () {
      expect(kAuthEmailRedirect, 'https://papemosque.ca/hesap/onaylandi');
    });
  });

  group('email templates', () {
    String file(String name) => File('docs/email-templates/$name').readAsStringSync();

    test('each shows the code, in all three languages', () {
      for (final name in ['confirm-signup.html', 'reset-password.html', 'change-email.html']) {
        final html = file(name);
        expect(html, contains('{{ .Token }}'), reason: name);
        for (final tag in ['>TR<', '>EN<', '>FR<']) {
          expect(html, contains(tag), reason: '$name $tag');
        }
        expect(html, isNot(contains('<script')), reason: name);
        expect(RegExp(r'<img ').allMatches(html).length, 1, reason: '$name: the logo only');
        expect(html, contains('src="https://papemosque.ca/email/logo.png"'), reason: name);
      }
    });

    test('reset: the code for the app, the link for the panel', () {
      final html = file('reset-password.html');
      final branch = '{{ if eq .RedirectTo "$kAuthEmailRedirect" }}';
      expect(html, contains(branch));
      final app = html.substring(html.indexOf(branch), html.indexOf('{{ else }}'));
      final panel = html.substring(html.indexOf('{{ else }}'), html.indexOf('{{ end }}'));
      expect(app, contains('{{ .Token }}'));
      expect(app, isNot(contains('{{ .ConfirmationURL }}')));
      expect(panel, contains('{{ .ConfirmationURL }}'));
      expect(file('README.md'), contains(kAuthEmailRedirect));
    });
  });

  group('screens', () {
    late FakeEmailAuth fake;
    late EmailAuth original;

    setUp(() {
      original = EmailAuth.instance;
      fake = FakeEmailAuth();
      EmailAuth.instance = fake;
    });
    tearDown(() => EmailAuth.instance = original);

    Future<GoRouter> pump(WidgetTester tester, String start) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('PROFILE')),
            routes: [
              GoRoute(path: 'sign-in', builder: (_, _) => const SignInScreen()),
              GoRoute(path: 'sign-up', builder: (_, _) => const SignUpScreen()),
              GoRoute(
                path: 'confirm-email',
                builder: (_, s) {
                  final a = s.extra! as ConfirmEmailArgs;
                  return ConfirmEmailScreen(email: a.email, sendOnOpen: a.sendOnOpen);
                },
              ),
              GoRoute(
                path: 'reset-password',
                builder: (_, s) => ResetPasswordScreen(email: s.extra as String? ?? ''),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [userProfileProvider.overrideWith((ref) async => null)],
          child: MaterialApp.router(
            theme: appLightTheme,
            locale: const Locale('tr'),
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
      );
      router.push(start);
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> type(WidgetTester tester, String label, String text) async {
      final field = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'AppField'),
      );
      await tester.enterText(
        find.descendant(of: field, matching: find.byType(TextField)),
        text,
      );
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    final code = find.byKey(const ValueKey('email-code'));

    Future<void> fillSignUp(WidgetTester tester) async {
      await type(tester, 'Ad soyad', 'Ayşe Yılmaz');
      await type(tester, 'E-posta', 'ayse@example.com');
      await type(tester, 'Şifre', 'secret12');
      final state = tester.state(find.byType(SignUpScreen)) as dynamic;
      // The date picker is tested elsewhere; set the chosen date directly.
      state.debugSetBirthDate(DateTime(1990, 5, 1));
      await tester.pump();
    }

    testWidgets('sign-up without a session asks for the code, which signs in', (tester) async {
      await pump(tester, '/profile/sign-up');
      await fillSignUp(tester);
      await tapText(tester, 'Hesabı oluştur');
      expect(fake.calls, ['signUp ayse@example.com']);
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);
      expect(find.textContaining('ayse@example.com'), findsOneWidget);
      expect(find.text('Kodu tekrar gönder (60 sn)'), findsOneWidget);
      expect(find.textContaining('daha sonra, giriş yaptığınızda'), findsOneWidget);

      // Typing the sixth digit sends it.
      await tester.enterText(code, '123456');
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'verifySignUp ayse@example.com 123456');
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('a wrong code stays on the screen with its message', (tester) async {
      fake.verifyError = err(AuthFailure.invalidCode);
      await pump(tester, '/profile/sign-up');
      await fillSignUp(tester);
      await tapText(tester, 'Hesabı oluştur');
      await tester.enterText(code, '000000');
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);
      expect(find.textContaining('Kod yanlış ya da süresi dolmuş'), findsOneWidget);
    });

    testWidgets('resend waits 60 s, then sends again', (tester) async {
      await pump(tester, '/profile/sign-up');
      await fillSignUp(tester);
      await tapText(tester, 'Hesabı oluştur');
      await tester.tap(find.text('Kodu tekrar gönder (60 sn)'));
      await tester.pump();
      expect(fake.calls.where((c) => c.startsWith('resend')), isEmpty);
      await tester.pump(const Duration(seconds: kResendCooldown));
      await tester.pump();
      await tapText(tester, 'Kodu tekrar gönder');
      expect(fake.calls.last, 'resendSignUp ayse@example.com');
      expect(find.text('Yeni bir kod gönderildi.'), findsOneWidget);
      expect(find.text('Kodu tekrar gönder (60 sn)'), findsOneWidget);
    });

    testWidgets('an address with an account: sign-in and reset offered', (tester) async {
      fake.signUpOutcome = (result: SignUpResult.alreadyRegistered, error: null);
      await pump(tester, '/profile/sign-up');
      await fillSignUp(tester);
      await tapText(tester, 'Hesabı oluştur');
      expect(find.byType(ConfirmEmailScreen), findsNothing);
      expect(find.textContaining('zaten bir hesap var'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('registered-reset')));
      await tester.pumpAndSettle();
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('ayse@example.com'), findsOneWidget);
    });

    testWidgets('sign-in refused as unconfirmed sends a code and asks for it', (tester) async {
      fake.signInError = err(AuthFailure.emailNotConfirmed);
      await pump(tester, '/profile/sign-in');
      await type(tester, 'E-posta', 'ayse@example.com');
      await type(tester, 'Şifre', 'secret12');
      await tapText(tester, 'Giriş yap');
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);
      expect(fake.calls, ['signIn ayse@example.com', 'resendSignUp ayse@example.com']);
      await tester.enterText(code, '654321');
      await tester.pumpAndSettle();
      // Both the code screen and sign-in close.
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('forgot password: email, code, new password, signed in', (tester) async {
      await pump(tester, '/profile/sign-in');
      await type(tester, 'E-posta', 'ayse@example.com');
      await tester.tap(find.byKey(const ValueKey('forgot-password')));
      await tester.pumpAndSettle();
      expect(find.text('Şifrenizi sıfırlayın'), findsOneWidget);
      await tapText(tester, 'Kod gönder');
      expect(fake.calls, ['reset ayse@example.com']);
      expect(find.textContaining('bir hesaba bağlıysa'), findsOneWidget);
      await tester.enterText(code, '111222');
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'verifyRecovery ayse@example.com 111222');
      await type(tester, 'Yeni şifre', '12');
      await tapText(tester, 'Şifreyi kaydet');
      expect(find.text('Şifre en az 6 karakter olmalıdır.'), findsOneWidget);
      await type(tester, 'Yeni şifre', 'newsecret');
      await tapText(tester, 'Şifreyi kaydet');
      expect(fake.calls.last, 'setNewPassword');
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('an address without an account reads exactly like one with', (tester) async {
      // What Supabase may answer for an unknown address; the screen hides it.
      fake.resetError = resetRequestError(err(AuthFailure.unexpected));
      await pump(tester, '/profile/reset-password');
      await type(tester, 'E-posta', 'nobody@example.com');
      await tapText(tester, 'Kod gönder');
      expect(find.textContaining('bir hesaba bağlıysa'), findsOneWidget);
      expect(find.byType(EmailCodeField), findsOneWidget);
    });
  });
}
