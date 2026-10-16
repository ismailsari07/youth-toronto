import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/features/profile/screens/sign_in_screen.dart';
import 'package:myt_flutter/features/profile/screens/sign_up_screen.dart';
import 'package:myt_flutter/features/profile/widgets/social_sign_in_buttons.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  final apple = find.byKey(const Key('apple-sign-in'));
  final google = find.byKey(const Key('google-sign-in'));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme ?? appLightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    );
    await tester.pump();
  }

  Widget buttons({VoidCallback? onApple, VoidCallback? onGoogle}) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SocialSignInButtons(onApple: onApple, onGoogle: onGoogle),
        ),
      );

  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  group('on iOS', () {
    testWidgets('Apple first, Google second, the same size', (tester) async {
      await pump(tester, buttons(onApple: () {}, onGoogle: () {}));
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      final a = tester.getRect(apple);
      final g = tester.getRect(google);
      expect(a.top, lessThan(g.top));
      expect(a.size, g.size, reason: 'Apple at least as prominent as Google');
      expect(a.height, SocialSignInButtons.height);
    }, variant: iOS);

    testWidgets('taps reach the handlers; disabled while busy', (tester) async {
      final taps = <String>[];
      await pump(
        tester,
        buttons(onApple: () => taps.add('apple'), onGoogle: () => taps.add('google')),
      );
      await tester.tap(apple);
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(taps, ['apple', 'google']);

      await pump(tester, buttons());
      await tester.tap(apple);
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(taps, ['apple', 'google']);
    }, variant: iOS);

    testWidgets('Apple button is black in light mode, white in dark',
        (tester) async {
      await pump(tester, buttons(onApple: () {}, onGoogle: () {}));
      expect(tester.widget<SignInWithAppleButton>(apple).style,
          SignInWithAppleButtonStyle.black);
      await pump(tester, buttons(onApple: () {}, onGoogle: () {}),
          theme: appDarkTheme);
      await tester.pumpAndSettle(); // MaterialApp animates the theme change.
      expect(tester.widget<SignInWithAppleButton>(apple).style,
          SignInWithAppleButtonStyle.white);
    }, variant: iOS);

    testWidgets('localized in Turkish and French', (tester) async {
      await pump(tester, buttons(), locale: const Locale('tr'));
      expect(find.text('Apple ile devam et'), findsOneWidget);
      expect(find.text('Google ile devam et'), findsOneWidget);
      expect(find.text('veya'), findsOneWidget);
      await pump(tester, buttons(), locale: const Locale('fr'));
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
    }, variant: iOS);

    testWidgets('sign-in screen: the buttons sit above the email form',
        (tester) async {
      await pump(tester, const SignInScreen());
      expect(apple, findsOneWidget);
      expect(google, findsOneWidget);
      expect(tester.getRect(google).bottom,
          lessThan(tester.getTopLeft(find.text('Email')).dy));
    }, variant: iOS);

    testWidgets('sign-up screen: the buttons sit above the form',
        (tester) async {
      await pump(tester, const SignUpScreen());
      expect(apple, findsOneWidget);
      expect(tester.getRect(google).bottom,
          lessThan(tester.getTopLeft(find.text('Full name')).dy));
    }, variant: iOS);
  });

  testWidgets('hidden on other platforms', (tester) async {
    await pump(tester, buttons(onApple: () {}, onGoogle: () {}));
    expect(apple, findsNothing);
    expect(google, findsNothing);
    expect(find.text('or'), findsNothing);
    await pump(tester, const SignInScreen());
    expect(apple, findsNothing);
    expect(find.text('Email'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
