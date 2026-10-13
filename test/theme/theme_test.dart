import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/theme/app_tokens.dart';
import 'package:myt_flutter/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG contrast of [fg] over [bg]; a translucent [fg] is composited first,
/// and a translucent [bg] over [under].
double contrast(Color fg, Color bg, {Color? under}) {
  final base = under == null ? bg : Color.alphaBlend(bg, under);
  final top = Color.alphaBlend(fg, base);
  final a = top.computeLuminance();
  final b = base.computeLuminance();
  return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
}

void main() {
  group('appearance choice', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('follows the system until the member picks', () async {
      expect(await ThemeModeStore.load(), ThemeMode.system);
    });

    test('a choice reads back, and System clears it', () async {
      await ThemeModeStore.save(ThemeMode.dark);
      expect(await ThemeModeStore.load(), ThemeMode.dark);
      await ThemeModeStore.save(ThemeMode.light);
      expect(await ThemeModeStore.load(), ThemeMode.light);
      await ThemeModeStore.save(ThemeMode.system);
      expect(await ThemeModeStore.load(), ThemeMode.system);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('app_theme_mode'), isFalse);
    });

    test('an unknown stored value falls back to the system', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'sepia'});
      expect(await ThemeModeStore.load(), ThemeMode.system);
    });
  });

  test('both themes carry their palette and shadows', () {
    expect(appLightTheme.extension<AppColors>(), AppColors.light);
    expect(appDarkTheme.extension<AppColors>(), AppColors.dark);
    expect(appLightTheme.extension<AppShadows>(), AppShadows.light);
    expect(appDarkTheme.extension<AppShadows>(), AppShadows.dark);
    expect(appDarkTheme.brightness, Brightness.dark);
    expect(appDarkTheme.scaffoldBackgroundColor, AppColors.dark.ground);
  });

  group('dark text meets WCAG AA (4.5:1)', () {
    const c = AppColors.dark;
    final pairs = <String, double>{
      'ink on card': contrast(c.ink, c.card),
      'ink2 on card': contrast(c.ink2, c.card),
      'ink3 on card': contrast(c.ink3, c.card),
      'ink3 on ground': contrast(c.ink3, c.ground),
      'ink3 on the last grouped row': contrast(c.ink3, c.cardMuted),
      'green on card': contrast(c.green, c.card),
      'label on green (NOW, buttons)': contrast(c.onGreen, c.green),
      'active prayer row text':
          contrast(c.greenDeep, c.greenRowBg, under: c.card),
      'IQAMAH label on the active row':
          contrast(c.greenLabel, c.greenRowBg, under: c.card),
      'Hijri / status pill text':
          contrast(c.greenDeep, c.greenTint, under: c.ground),
      'gold title': contrast(c.goldText, c.goldBg),
      'gold subtitle': contrast(c.goldTextSoft, c.goldBg),
      'info banner': contrast(c.blue, c.blueTint, under: c.ground),
      'warning banner': contrast(c.amber, c.amberTint, under: c.ground),
      'urgent banner': contrast(c.danger, c.dangerTint, under: c.ground),
      'label on danger button': contrast(c.onDanger, c.danger),
      'inactive tab': contrast(c.tabInactive, c.card),
      'secondary text on the hero':
          contrast(c.onHeroSecondary, c.gradTop),
    };
    for (final MapEntry(:key, :value) in pairs.entries) {
      test(key, () => expect(value, greaterThanOrEqualTo(4.5)));
    }
  });
}
