import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/feature_flags.dart';
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

  Widget buttons({
    VoidCallback? onApple,
    VoidCallback? onGoogle,
    bool? showGoogle,
  }) =>
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: showGoogle == null
              ? SocialSignInButtons(onApple: onApple, onGoogle: onGoogle)
              : SocialSignInButtons(
                  onApple: onApple,
                  onGoogle: onGoogle,
                  showGoogle: showGoogle,
                ),
        ),
      );

  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  test('1.1.0 ships Apple only', () {
    expect(kGoogleSignInEnabled, isFalse);
  });

  group('on iOS', () {
    testWidgets('Apple only: no Google button', (tester) async {
      await pump(tester, buttons(onApple: () {}, onGoogle: () {}));
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(google, findsNothing);
      expect(find.text('Continue with Google'), findsNothing);
      expect(tester.getRect(apple).height, SocialSignInButtons.height);
    }, variant: iOS);

    testWidgets('Apple tap reaches the handler; disabled while busy',
        (tester) async {
      var taps = 0;
      await pump(tester, buttons(onApple: () => taps++));
      await tester.tap(apple);
      await tester.pumpAndSettle();
      expect(taps, 1);

      await pump(tester, buttons());
      await tester.tap(apple);
      await tester.pumpAndSettle();
      expect(taps, 1);
    }, variant: iOS);

    testWidgets('Apple button is black in light mode, white in dark',
        (tester) async {
      await pump(tester, buttons(onApple: () {}));
      expect(tester.widget<SignInWithAppleButton>(apple).style,
          SignInWithAppleButtonStyle.black);
      await pump(tester, buttons(onApple: () {}), theme: appDarkTheme);
      await tester.pumpAndSettle(); // MaterialApp animates the theme change.
      expect(tester.widget<SignInWithAppleButton>(apple).style,
          SignInWithAppleButtonStyle.white);
    }, variant: iOS);

    testWidgets('localized in Turkish and French', (tester) async {
      await pump(tester, buttons(), locale: const Locale('tr'));
      expect(find.text('Apple ile devam et'), findsOneWidget);
      expect(find.text('veya'), findsOneWidget);
      await pump(tester, buttons(), locale: const Locale('fr'));
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      expect(find.text('ou'), findsOneWidget);
    }, variant: iOS);

    testWidgets('sign-in screen: Apple above the email form, no Google',
        (tester) async {
      await pump(tester, const SignInScreen());
      expect(google, findsNothing);
      expect(tester.getRect(apple).bottom,
          lessThan(tester.getTopLeft(find.text('Email')).dy));
    }, variant: iOS);

    testWidgets('sign-up screen: Apple above the form, no Google',
        (tester) async {
      await pump(tester, const SignUpScreen());
      expect(google, findsNothing);
      expect(tester.getRect(apple).bottom,
          lessThan(tester.getTopLeft(find.text('Full name')).dy));
    }, variant: iOS);

    // For the day kGoogleSignInEnabled is turned on (App Review 4.8).
    testWidgets('with Google on: Apple first, the same size, both tappable',
        (tester) async {
      final taps = <String>[];
      await pump(
        tester,
        buttons(
          onApple: () => taps.add('apple'),
          onGoogle: () => taps.add('google'),
          showGoogle: true,
        ),
      );
      final a = tester.getRect(apple);
      final g = tester.getRect(google);
      expect(a.top, lessThan(g.top));
      expect(a.size, g.size, reason: 'Apple at least as prominent as Google');
      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(apple);
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(taps, ['apple', 'google']);
    }, variant: iOS);
  });

  testWidgets('hidden on other platforms', (tester) async {
    await pump(tester, buttons(onApple: () {}, onGoogle: () {}, showGoogle: true));
    expect(apple, findsNothing);
    expect(google, findsNothing);
    expect(find.text('or'), findsNothing);
    await pump(tester, const SignInScreen());
    expect(apple, findsNothing);
    expect(find.text('Email'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
