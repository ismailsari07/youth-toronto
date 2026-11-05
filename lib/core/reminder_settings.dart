/// The sound of a prayer notification.
enum ReminderSound { athan, standard, silent }

/// The device's prayer-notification choices. Every reminder fires at the
/// athan; there is nothing to choose about when. A missing prayer list reads
/// as all five.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.prayers = allPrayers,
    this.sound,
  });

  /// The five daily prayers, as prayer_cache names them. No Sunrise.
  static const allPrayers = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};

  /// The master switch.
  final bool enabled;
  final Set<String> prayers;

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
    ReminderSound? sound,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
        sound: sound ?? this.sound,
      );
}
