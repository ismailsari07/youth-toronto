import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notification_sounds.dart';
import '../../core/reminder_settings.dart';
import '../../core/reminder_sync.dart';

/// The device's prayer-notification settings: the one source for the bell,
/// its sheet and the summary rows on Prayer, Profile and Settings, so every
/// place always shows the same state. Storage and scheduling stay with
/// [ReminderSync].
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);

/// Whether this build carries the athan recording (see [NotificationSounds]).
final athanBundledProvider =
    FutureProvider<bool>((ref) => NotificationSounds.athanBundled());

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() => ReminderSync.loadSettings();

  ReminderSettings get _current => state.valueOrNull ?? const ReminderSettings();

  /// The master switch. Turning it on with every prayer switched off brings
  /// all five back, so "on" always means something is scheduled.
  Future<void> setEnabled(bool on) => _save(
        _current.copyWith(
          enabled: on,
          prayers: on && _current.prayers.isEmpty
              ? ReminderSettings.allPrayers
              : null,
        ),
      );

  /// Switching off the last prayer turns the master switch off too.
  Future<void> setPrayer(String prayer, bool on) {
    final prayers = {..._current.prayers};
    on ? prayers.add(prayer) : prayers.remove(prayer);
    return _save(
      _current.copyWith(
        prayers: prayers,
        enabled: prayers.isEmpty ? false : null,
      ),
    );
  }

  Future<void> setTiming(ReminderTiming timing) =>
      _save(_current.copyWith(timing: timing));

  Future<void> setSound(ReminderSound sound) =>
      _save(_current.copyWith(sound: sound));

  /// Shows the change at once, saves it, then re-syncs: scheduling (and the
  /// permission prompt) when on, cancelling when off. Completes once the
  /// sync has run.
  Future<void> _save(ReminderSettings next) async {
    state = AsyncData(next);
    await ReminderSync.saveSettings(next);
    await ReminderSync.sync();
  }
}
