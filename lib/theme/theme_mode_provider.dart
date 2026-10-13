import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The member's saved appearance, read in main() before the first frame so
/// the app never flashes the wrong mode.
final savedThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// System / Light / Dark. MaterialApp watches it; [ThemeMode.system] follows
/// the iOS setting, live.
final themeModeProvider =
    NotifierProvider<ThemeModeOverride, ThemeMode>(ThemeModeOverride.new);

class ThemeModeOverride extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(savedThemeModeProvider);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ThemeModeStore.save(mode);
  }
}

/// The choice on this device, in shared preferences. Absent = follow the
/// system.
abstract final class ThemeModeStore {
  static const _prefKey = 'app_theme_mode';

  static Future<ThemeMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return switch (prefs.getString(_prefKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, mode.name);
    }
  }
}
