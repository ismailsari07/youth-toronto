/// When a prayer notification arrives. Only one at a time, so the schedule
/// stays at most 5 prayers × 7 days = 35 (iOS keeps at most 64).
enum ReminderTiming { atAthan, beforeIqamah }

/// The sound of the athan-time notification. The 5-minutes-before-iqamah
/// notification always uses the standard sound.
enum ReminderSound { athan, standard, silent }

/// The device's prayer-notification choices. Missing values read as the
/// original behaviour, so members from before these options keep exactly
/// what they had: all five prayers, 5 minutes before the iqamah.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.prayers = allPrayers,
    this.timing = ReminderTiming.beforeIqamah,
    this.sound,
  });

  /// The five daily prayers, as prayer_cache names them. No Sunrise.
  static const allPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};

  /// The master switch.
  final bool enabled;
  final Set<String> prayers;
  final ReminderTiming timing;

  /// The member's choice, or null if they never picked one.
  final ReminderSound? sound;

  /// Whether anything gets scheduled.
  bool get active => enabled && prayers.isNotEmpty;

  /// The sound actually used. The athan is the default once its recording
  /// is in the app ([athanBundled]); until then, and for anyone who picked
  /// it on a build that had it, the standard sound stands in.
  ReminderSound soundWith({required bool athanBundled}) {
    final chosen = sound;
    if (chosen == null) {
      return athanBundled ? ReminderSound.athan : ReminderSound.standard;
    }
    if (chosen == ReminderSound.athan && !athanBundled) {
      return ReminderSound.standard;
    }
    return chosen;
  }

  ReminderSettings copyWith({
    bool? enabled,
    Set<String>? prayers,
    ReminderTiming? timing,
    ReminderSound? sound,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
        timing: timing ?? this.timing,
        sound: sound ?? this.sound,
      );
}
