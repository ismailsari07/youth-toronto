import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reminder_sync.dart';

/// The device's prayer-reminder setting, shared by every switch that shows
/// it (Prayer home, its bell sheet, Profile, Settings), so flipping one
/// moves them all. Storage and scheduling stay with [ReminderSync].
final remindersEnabledProvider =
    AsyncNotifierProvider<RemindersEnabled, bool>(RemindersEnabled.new);

class RemindersEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ReminderSync.isEnabled();

  /// Saves the choice and re-syncs: scheduling (and the permission prompt)
  /// when on, cancelling when off. Completes once the sync has run.
  Future<void> set(bool enabled) async {
    state = AsyncData(enabled);
    await ReminderSync.setEnabled(enabled);
    await ReminderSync.sync();
  }
}
