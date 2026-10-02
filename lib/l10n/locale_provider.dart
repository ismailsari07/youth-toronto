import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/reminder_sync.dart';
import 'l10n.dart';

/// The member's saved choice, read in main() before the first frame so the
/// app never flashes the wrong language.
final savedLocaleProvider = Provider<Locale?>((ref) => null);

/// The language override: null follows the device. MaterialApp watches it,
/// so changing it rebuilds every screen in the new language.
final localeOverrideProvider =
    NotifierProvider<LocaleOverride, Locale?>(LocaleOverride.new);

class LocaleOverride extends Notifier<Locale?> {
  @override
  Locale? build() => ref.watch(savedLocaleProvider);

  Future<void> set(Locale? locale) async {
    state = locale;
    await LocaleStore.save(locale);
    // Reminders already scheduled carry their text; re-create them in the
    // new language.
    ReminderSync.sync();
  }
}
