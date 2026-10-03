import 'package:flutter/material.dart';

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

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: kFontText,
  fontFamilyFallback: kFontFallback,
  scaffoldBackgroundColor: AppColor.ground,
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
  colorScheme: const ColorScheme.light(
    primary: AppColor.green,
    onPrimary: Colors.white,
    secondary: AppColor.blue,
    surface: AppColor.card,
    onSurface: AppColor.ink,
    error: AppColor.danger,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColor.hairline,
    thickness: 1,
    space: 1,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColor.ink),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColor.green,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColor.ink,
    contentTextStyle: AppText.rowTitle.c(Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);

/// Spec §0: the top 59px is reserved, but never less than the device's own
/// safe-area inset (notch devices report more).
double topInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top > AppSpace.safeTop
        ? MediaQuery.paddingOf(context).top
        : AppSpace.safeTop;
