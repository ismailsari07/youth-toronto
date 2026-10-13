import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'app_tokens.dart';

// Type on Apple devices resolves to SF Pro through these aliases;
// 'CupertinoSystemDisplay' is Apple's guidance for 20pt and above. On Android
// and desktop both fall through to the bundled Manrope.
const String kFontText = 'CupertinoSystemText';
const String kFontDisplay = 'CupertinoSystemDisplay';
const List<String> kFontFallback = ['Manrope'];

/// Applies the system-font families to a token text style. Sizes of 20 and up
/// get the display face, per Apple's guidance.
extension AppTextFamily on TextStyle {
  TextStyle get sys => copyWith(
        fontFamily: (fontSize ?? 16) >= 20 ? kFontDisplay : kFontText,
        fontFamilyFallback: kFontFallback,
      );

  TextStyle c(Color color) => sys.copyWith(color: color);
}

/// The light and dark themes. Every colour comes from [AppColors]; widgets
/// read it with `context.colors`.
final ThemeData appLightTheme = _theme(AppColors.light, AppShadows.light);
final ThemeData appDarkTheme = _theme(AppColors.dark, AppShadows.dark);

ThemeData _theme(AppColors c, AppShadows shadows) => ThemeData(
      brightness: c.brightness,
      fontFamily: kFontText,
      fontFamilyFallback: kFontFallback,
      scaffoldBackgroundColor: c.ground,
      canvasColor: c.ground,
      extensions: [c, shadows],
      // The iOS slide everywhere, so a push feels the same on every device.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.green,
        onPrimary: c.onGreen,
        secondary: c.blue,
        onSecondary: c.onGreen,
        surface: c.card,
        onSurface: c.ink,
        error: c.danger,
        onError: c.onDanger,
      ),
      dividerTheme: DividerThemeData(
        color: c.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.green),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.green,
        selectionColor: c.greenTintStrong,
        selectionHandleColor: c.green,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBg,
        contentTextStyle: AppText.rowTitle.c(c.snackText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

/// Status-bar icons for a screen whose top is [background]'s brightness:
/// light icons over the dark hero, and on the ground in dark mode.
SystemUiOverlayStyle statusBarOver(Brightness background) =>
    background == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

/// Spec §0: the top 59px is reserved, but never less than the device's own
/// safe-area inset (notch devices report more).
double topInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top > AppSpace.safeTop
        ? MediaQuery.paddingOf(context).top
        : AppSpace.safeTop;
